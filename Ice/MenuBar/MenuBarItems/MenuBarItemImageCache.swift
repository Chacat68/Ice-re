//
//  MenuBarItemImageCache.swift
//  Ice
//

import Cocoa
import Combine

/// Cache entry with access time tracking for LRU eviction.
private struct CacheEntry {
    let image: CGImage
    var lastAccessed: Date

    init(image: CGImage) {
        self.image = image
        self.lastAccessed = Date()
    }
}

/// Cache for menu bar item images with LRU eviction policy.
final class MenuBarItemImageCache: ObservableObject {
    /// The cached item images with access tracking.
    @Published private(set) var images = [MenuBarItemInfo: CGImage]()

    /// Internal cache with access tracking for LRU eviction.
    private var cache = [MenuBarItemInfo: CacheEntry]()

    /// Maximum cache size in bytes (approximately 50MB).
    private let maxCacheSize: Int = 50 * 1024 * 1024

    /// Current cache size in bytes.
    private var currentCacheSize: Int = 0

    /// Cache access queue for thread safety.
    private let cacheQueue = DispatchQueue(label: "com.jordanteacher.Veil.imageCache", attributes: .concurrent)

    /// The screen of the cached item images.
    private(set) var screen: NSScreen?

    /// The height of the menu bar of the cached item images.
    private(set) var menuBarHeight: CGFloat?

    /// The shared app state.
    private weak var appState: AppState?

    /// Storage for internal observers.
    private var cancellables = Set<AnyCancellable>()

    /// Creates a cache with the given app state.
    init(appState: AppState) {
        self.appState = appState
    }

    /// Sets up the cache.
    @MainActor
    func performSetup() {
        configureCancellables()
    }

    /// Configures the internal observers for the cache.
    @MainActor
    private func configureCancellables() {
        var c = Set<AnyCancellable>()

        if let appState {
            Publishers.Merge3(
                // Update every 3 seconds at minimum.
                Timer.publish(every: 3, on: .main, in: .default).autoconnect().mapToVoid(),

                // Update when the active space or screen parameters change.
                Publishers.Merge(
                    NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification),
                    NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
                )
                .mapToVoid(),

                // Update when the average menu bar color or cached items change.
                Publishers.Merge(
                    appState.menuBarManager.$averageColorInfo.removeDuplicates().mapToVoid(),
                    appState.itemManager.$itemCache.removeDuplicates().mapToVoid()
                )
            )
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] in
                guard let self else {
                    return
                }
                // Check permissions on main actor before starting async work
                let hasPermissions = ScreenCapture.cachedCheckPermissions()
                Task { [weak self] in
                    guard let self else { return }
                    if hasPermissions {
                        await updateCache()
                    }
                }
            }
            .store(in: &c)
        }

        cancellables = c
    }

    /// Logs a reason for skipping the cache.
    private func logSkippingCache(reason: String) {
        // Logger.imageCache.debug("Skipping menu bar item image cache as \(reason)")
    }

    /// Returns a Boolean value that indicates whether caching menu bar items failed for
    /// the given section.
    @MainActor
    func cacheFailed(for section: MenuBarSection.Name) -> Bool {
        guard ScreenCapture.cachedCheckPermissions() else {
            return true
        }
        let items = appState?.itemManager.itemCache[section] ?? []
        guard !items.isEmpty else {
            return false
        }
        let keys = Set(images.keys)
        for item in items where keys.contains(item.info) {
            return false
        }
        return true
    }

    /// Captures the images of the current menu bar items and returns a dictionary containing
    /// the images, keyed by the current menu bar item infos.
    func createImages(for section: MenuBarSection.Name, screen: NSScreen) async -> [MenuBarItemInfo: CGImage] {
        guard let appState else {
            return [:]
        }

        let items = await appState.itemManager.itemCache[section]

        var images = [MenuBarItemInfo: CGImage]()
        let backingScaleFactor = screen.backingScaleFactor
        let displayBounds = CGDisplayBounds(screen.displayID)
        let option: CGWindowImageOption = [.boundsIgnoreFraming, .bestResolution]
        let defaultItemThickness = NSStatusBar.system.thickness * backingScaleFactor

        // First, try to get icons from app bundles (no screen recording permission needed)
        let iconProvider = MenuBarItemIconProvider.shared
        var itemsNeedingScreenshot = [MenuBarItem]()

        for item in items {
            if let bundleIcon = iconProvider.getIcon(for: item),
                let cgImage = bundleIcon.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                images[item.info] = cgImage
            } else {
                // Mark for screenshot fallback
                itemsNeedingScreenshot.append(item)
            }
        }

        // If we have all icons from bundles, return early
        if itemsNeedingScreenshot.isEmpty {
            return images
        }

        // Fallback: Use screen capture for items without bundle icons
        var itemInfos = [CGWindowID: MenuBarItemInfo]()
        var itemFrames = [CGWindowID: CGRect]()
        var windowIDs = [CGWindowID]()
        var frame = CGRect.null

        for item in itemsNeedingScreenshot {
            let windowID = item.windowID
            guard
                // Use the most up-to-date window frame.
                let itemFrame = Bridging.getWindowFrame(for: windowID),
                itemFrame.minY == displayBounds.minY
            else {
                continue
            }
            itemInfos[windowID] = item.info
            itemFrames[windowID] = itemFrame
            windowIDs.append(windowID)
            frame = frame.union(itemFrame)
        }

        if
            let compositeImage = ScreenCapture.captureWindows(windowIDs, option: option),
            CGFloat(compositeImage.width) == frame.width * backingScaleFactor
        {
            for windowID in windowIDs {
                guard
                    let itemInfo = itemInfos[windowID],
                    let itemFrame = itemFrames[windowID]
                else {
                    continue
                }

                let frame = CGRect(
                    x: (itemFrame.origin.x - frame.origin.x) * backingScaleFactor,
                    y: (itemFrame.origin.y - frame.origin.y) * backingScaleFactor,
                    width: itemFrame.width * backingScaleFactor,
                    height: itemFrame.height * backingScaleFactor
                )

                guard let itemImage = compositeImage.cropping(to: frame) else {
                    continue
                }

                images[itemInfo] = itemImage
            }
        } else {
            Logger.imageCache.warning("Composite image capture failed. Attempting to capturing items individually.")

            for windowID in windowIDs {
                guard
                    let itemInfo = itemInfos[windowID],
                    let itemFrame = itemFrames[windowID]
                else {
                    continue
                }

                let frame = CGRect(
                    x: 0,
                    y: ((itemFrame.height * backingScaleFactor) / 2) - (defaultItemThickness / 2),
                    width: itemFrame.width * backingScaleFactor,
                    height: defaultItemThickness
                )

                guard
                    let itemImage = ScreenCapture.captureWindow(windowID, option: option),
                    let croppedImage = itemImage.cropping(to: frame)
                else {
                    continue
                }

                images[itemInfo] = croppedImage
            }
        }

        return images
    }

    /// Updates the cache for the given sections, without checking whether caching is necessary.
    func updateCacheWithoutChecks(sections: [MenuBarSection.Name]) async {
        guard
            let appState,
            let screen = NSScreen.main
        else {
            return
        }

        var newImages = [MenuBarItemInfo: CGImage]()

        for section in sections {
            guard await !appState.itemManager.itemCache[section].isEmpty else {
                continue
            }
            let sectionImages = await createImages(for: section, screen: screen)
            guard !sectionImages.isEmpty else {
                Logger.imageCache.warning("Update image cache failed for \(section.logString)")
                continue
            }
            newImages.merge(sectionImages) { (_, new) in new }
        }

        await MainActor.run { [newImages] in
            // Update cache with new images using LRU policy
            for (info, image) in newImages {
                setImageWithLRU(info, image)
            }
        }

        self.screen = screen
        self.menuBarHeight = screen.getMenuBarHeight()
    }

    /// Sets an image in the cache with LRU eviction policy.
    private func setImageWithLRU(_ info: MenuBarItemInfo, _ image: CGImage) {
        let imageSize = estimateImageSize(image)

        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            // Remove old entry if exists
            if let oldEntry = self.cache[info] {
                self.currentCacheSize -= estimateImageSize(oldEntry.image)
            }

            // Add new entry
            let entry = CacheEntry(image: image)
            self.cache[info] = entry
            self.currentCacheSize += imageSize

            // Evict LRU entries if cache is too large
            self.evictLRUIfNeeded()

            // Update published images
            self.images[info] = image
        }
    }

    /// Estimates the size of an image in bytes.
    private func estimateImageSize(_ image: CGImage) -> Int {
        let bytesPerRow = image.bytesPerRow
        let height = image.height
        return bytesPerRow * height
    }

    /// Evicts least recently used cache entries if cache size exceeds limit.
    private func evictLRUIfNeeded() {
        guard currentCacheSize > maxCacheSize else { return }

        // Sort entries by last accessed time
        let sortedEntries = cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }

        // Remove oldest entries until cache is under limit
        for (info, entry) in sortedEntries {
            if currentCacheSize <= maxCacheSize * 3 / 4 { // Target 75% of max size
                break
            }

            let size = estimateImageSize(entry.image)
            cache.removeValue(forKey: info)
            images.removeValue(forKey: info)
            currentCacheSize -= size
        }
    }

    /// Updates the cache for the given sections, if necessary.
    func updateCache(sections: [MenuBarSection.Name]) async {
        guard let appState else {
            return
        }

        let isIceBarPresented = await appState.navigationState.isIceBarPresented
        let isSearchPresented = await appState.navigationState.isSearchPresented

        if !isIceBarPresented && !isSearchPresented {
            guard await appState.navigationState.isAppFrontmost else {
                logSkippingCache(reason: "Ice Bar not visible, app not frontmost")
                return
            }
            guard await appState.navigationState.isSettingsPresented else {
                logSkippingCache(reason: "Ice Bar not visible, Settings not visible")
                return
            }
            guard case .menuBarLayout = await appState.navigationState.settingsNavigationIdentifier else {
                logSkippingCache(reason: "Ice Bar not visible, Settings visible but not on Menu Bar Layout")
                return
            }
        }

        guard await !appState.itemManager.isMovingItem else {
            logSkippingCache(reason: "an item is currently being moved")
            return
        }

        guard await !appState.itemManager.itemHasRecentlyMoved else {
            logSkippingCache(reason: "an item was recently moved")
            return
        }

        await updateCacheWithoutChecks(sections: sections)
    }

    /// Updates the cache for all sections, if necessary.
    func updateCache() async {
        guard let appState else {
            return
        }

        let isIceBarPresented = await appState.navigationState.isIceBarPresented
        let isSearchPresented = await appState.navigationState.isSearchPresented
        let isSettingsPresented = await appState.navigationState.isSettingsPresented

        var sectionsNeedingDisplay = [MenuBarSection.Name]()
        if isSettingsPresented || isSearchPresented {
            sectionsNeedingDisplay = MenuBarSection.Name.allCases
        } else if
            isIceBarPresented,
            let section = await appState.menuBarManager.iceBarPanel.currentSection
        {
            sectionsNeedingDisplay.append(section)
        }

        await updateCache(sections: sectionsNeedingDisplay)
    }
}

// MARK: - Logger

private extension Logger {
    static let imageCache = Logger(category: "MenuBarItemImageCache")
}
