#!/bin/bash
set -e

# Configuration
APP_NAME="Veil"
PROJECT_NAME="Ice.xcodeproj"
SCHEME_NAME="Ice"
DMG_NAME="Veil.dmg"
VOL_NAME="Veil"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/Veil.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
SRC_APP="${EXPORT_PATH}/${APP_NAME}.app"
OUTPUT_DMG="${BUILD_DIR}/${DMG_NAME}"
TMP_DMG="${BUILD_DIR}/tmp_${DMG_NAME}"
SPARSE_IMAGE="${TMP_DMG}.sparseimage"

# Cleanup
echo "Cleaning up previous builds..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 0. Resolve Dependencies
echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project "${PROJECT_NAME}" -scheme "${SCHEME_NAME}"

# 1. Build and Archive
echo "Archiving project..."
xcodebuild archive \
    -project "${PROJECT_NAME}" \
    -scheme "${SCHEME_NAME}" \
    -archivePath "${ARCHIVE_PATH}" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    AD_HOC_CODE_SIGNING_ALLOWED=YES \
    > "${BUILD_DIR}/build_archive.log" 2>&1

# 2. Export (Extract) App
echo "Extracting app from archive..."
# Direct extraction since we are building unsigned/ad-hoc
if [ -d "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" ]; then
    mkdir -p "${EXPORT_PATH}"
    cp -R "${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app" "${EXPORT_PATH}/"
else
    echo "Error: App not found in archive."
    exit 1
fi

# 2.5 Re-sign embedded frameworks and the app (ad-hoc)
echo "Re-signing embedded frameworks and app..."
# Sign all frameworks first
if [ -d "${SRC_APP}/Contents/Frameworks" ]; then
    find "${SRC_APP}/Contents/Frameworks" -name "*.framework" -type d | while read framework; do
        echo "  Signing: ${framework}"
        codesign --force --deep --sign - "${framework}"
    done
    # Also sign any dylibs
    find "${SRC_APP}/Contents/Frameworks" -name "*.dylib" -type f | while read dylib; do
        echo "  Signing: ${dylib}"
        codesign --force --sign - "${dylib}"
    done
fi
# Sign the main app
echo "  Signing: ${SRC_APP}"
codesign --force --deep --sign - "${SRC_APP}"

# 3. Create DMG
echo "Creating temporary sparse image..."
# Create a 200MB sparse image (grows as needed)
hdiutil create -size 200m -volname "${VOL_NAME}" -type SPARSE -fs HFS+ -fsargs "-c c=64,a=16,e=16" "${TMP_DMG}"

echo "Mounting image..."
# Mount and capture mount point
MOUNT_POINT=$(hdiutil attach "${SPARSE_IMAGE}" -nobrowse -noverify -noautoopen | grep -E '/Volumes/' | awk -F'\t' '{print $3}')

if [ -z "${MOUNT_POINT}" ]; then
    echo "Error: Failed to mount image."
    exit 1
fi

echo "Mounted at: ${MOUNT_POINT}"

echo "Copying app to image..."
cp -R "${SRC_APP}" "${MOUNT_POINT}/"

echo "Creating Applications symlink..."
ln -s /Applications "${MOUNT_POINT}/Applications"

# 4. Styling with AppleScript
echo "Applying DMG styling..."
# We need to detach and re-attach consistently to ensure Finder handles it right,
# but usually operating on the open mount point is fine.
# We'll use osascript to set view options.

osascript <<EOF
tell application "Finder"
    tell disk "${VOL_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 100
        -- set background picture of theViewOptions to none
        
        update without registering applications
        delay 1

        -- Position Ice.app
        try
            set position of item "${APP_NAME}.app" of container window to {150, 200}
        end try
        
        -- Position Applications symlink
        try
            set position of item "Applications" of container window to {350, 200}
        end try
        
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Sync to ensure changes are written
sync

echo "Detaching image..."
hdiutil detach "${MOUNT_POINT}"

# 5. Convert to final DMG
echo "Converting to final compressed DMG..."
hdiutil convert "${SPARSE_IMAGE}" -format UDZO -imagekey zlib-level=9 -o "${OUTPUT_DMG}"

# Cleanup temporary files
rm -f "${SPARSE_IMAGE}"

echo "✅ Success! DMG created at: ${OUTPUT_DMG}"
