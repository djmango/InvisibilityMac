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
        Button("Record Audio") {
            Task {
                await screenRecorder.start()
            }
        }
        .hide(if: screenRecorder.isRunning)
        .keyboardShortcut("r", modifiers: .command)

        Button("Stop Recording") {
            Task {
                await screenRecorder.stop()
            }
        }
        .hide(if: !screenRecorder.isRunning)

        Divider()

        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 5)

        Button("Check for Updates") {
            updaterViewModel.updater.checkForUpdates()
        }
        .disabled(!updaterViewModel.canCheckForUpdates)

        SettingsLink {
            Label("Settings", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Gravity") {
            NSApplication.shared.terminate(self)
        }
        .keyboardShortcut("q", modifiers: .command)

        Divider()
    }
}

#Preview {
    MenuBarView()
}
