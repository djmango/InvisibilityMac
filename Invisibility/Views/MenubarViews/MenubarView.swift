//
//  MenubarView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import SwiftUI

struct MenubarView: View {
    @ObservedObject private var updaterViewModel = UpdaterViewModel.shared

    @State private var isUpdateHovered = false
    @State private var isSettingsHovered = false
    @State private var isQuitHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Invisibility")
                .font(.headline)
                .foregroundColor(Color.primary.opacity(0.5))

            Button("Toggle Panel") {
                WindowManager.shared.toggleWindow()
            }
            .keyboardShortcut("g", modifiers: .command)

            Divider()

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                .font(.body)
                .foregroundColor(Color.primary.opacity(0.5))

            Button("Check for Updates") {
                updaterViewModel.updater.checkForUpdates()
            }
            .disabled(!updaterViewModel.canCheckForUpdates)

            Button("Settings") {
                WindowManager.shared.showWindow()
                SettingsViewModel.shared.isShowingSettings.toggle()
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut("q", modifiers: .command)

            Divider()
        }
    }
}
