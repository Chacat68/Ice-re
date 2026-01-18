//
//  MenuBarLayoutSettingsPane.swift
//  Ice
//

import SwiftUI

struct MenuBarLayoutSettingsPane: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if !ScreenCapture.cachedCheckPermissions() {
            missingScreenRecordingPermission
        } else if appState.menuBarManager.isMenuBarHiddenBySystemUserDefaults {
            cannotArrange
        } else {
            IceForm(alignment: .leading, spacing: 20) {
                header
                layoutBars
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Text("Drag to arrange your menu bar items")
                .font(.headline)
            Spacer()
        }
    }

    @ViewBuilder
    private var layoutBars: some View {
        Form {
            Section {
                ForEach(MenuBarSection.Name.allCases, id: \.self) { section in
                    layoutBar(for: section)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .scrollContentBackground(.hidden)

        IceGroupBox {
            AnnotationView(
                alignment: .center,
                font: .callout.bold()
            ) {
                Label {
                    Text("Tip: you can also arrange menu bar items by Command + dragging them in the menu bar")
                } icon: {
                    Image(systemName: "lightbulb")
                }
            }
        }
    }

    @ViewBuilder
    private var cannotArrange: some View {
        Text("Ice cannot arrange menu bar items in automatically hidden menu bars")
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var missingScreenRecordingPermission: some View {
        VStack {
            Text("Menu bar layout requires screen recording permissions")
                .font(.title2)

            Button {
                appState.navigationState.settingsNavigationIdentifier = .advanced
            } label: {
                Text("Go to Advanced Settings")
            }
            .buttonStyle(.link)
        }
    }

    @ViewBuilder
    private func layoutBar(for section: MenuBarSection.Name) -> some View {
        if
            let section = appState.menuBarManager.section(withName: section),
            section.isEnabled
        {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(section.name.displayString) Section")
                    .font(.headline)
                    .padding(.horizontal, 4)

                IceGroupBox {
                    LayoutBar(section: section)
                        .environmentObject(appState.imageCache)
                        .padding(5)
                }
            }
        }
    }
}
