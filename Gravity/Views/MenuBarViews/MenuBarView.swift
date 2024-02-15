//
//  MenuBarView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import SwiftUI

struct MenuBarView: View {
    @StateObject private var screenRecorder = ScreenRecorder.shared
    @StateObject private var updaterViewModel = UpdaterViewModel.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                EventsView()

                Divider()

                Button("Record Audio") {
                    Task {
                        await screenRecorder.start()
                    }
                }
                .hide(if: screenRecorder.isRunning)
                .keyboardShortcut("r", modifiers: .command)
                .buttonStyle(.accessoryBar)

                Button("Stop Recording Audio") {
                    Task {
                        await screenRecorder.stop()
                    }
                }
                .hide(if: !screenRecorder.isRunning)
                .buttonStyle(.borderless)

                Divider()

                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Check for Updates") {
                    updaterViewModel.updater.checkForUpdates()
                }
                .disabled(!updaterViewModel.canCheckForUpdates)
                .buttonStyle(.accessoryBar)
                .selectionDisabled()

                SettingsLink {
                    // Label("Settings", systemImage: "gearshape")
                    Text("Settings")
                }
                .keyboardShortcut(",", modifiers: .command)
                .buttonStyle(.accessoryBar)
                .selectionDisabled()

                Divider()

                Button("Quit Gravity") {
                    NSApplication.shared.terminate(self)
                }
                .keyboardShortcut("q", modifiers: .command)
                .buttonStyle(.accessoryBar)
                .selectionDisabled()

                Divider()
            }
        }
        .padding(.horizontal, 8)
        .focusable(false)
    }
}

#Preview {
    MenuBarView()
}
