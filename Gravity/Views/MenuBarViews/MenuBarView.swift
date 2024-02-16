//
//  MenuBarView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/4/24.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var screenRecorder = ScreenRecorder.shared
    @ObservedObject private var updaterViewModel = UpdaterViewModel.shared

    @State private var isUpdateHovered = false
    @State private var isSettingsHovered = false
    @State private var isQuitHovered = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                EventsView()

                Divider()

                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                    .font(.body)
                    .foregroundColor(Color.primary.opacity(0.5))

                HStack {
                    Button("Check for Updates") {
                        updaterViewModel.updater.checkForUpdates()
                    }
                    .disabled(!updaterViewModel.canCheckForUpdates)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(isUpdateHovered ? Color("MenuBarButtonColor") : .clear)
                        .padding(-4)
                )
                .onHover { hovering in
                    isUpdateHovered = hovering
                }

                HStack {
                    SettingsLink {
                        Text("Settings")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    Spacer()
                    Text("⌘ ,")
                        .font(.system(size: 12))
                        .opacity(0.5)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(isSettingsHovered ? Color("MenuBarButtonColor") : .clear)
                        .padding(-4)
                )
                .onHover { hovering in
                    isSettingsHovered = hovering
                }

                Divider()

                HStack {
                    Button("Quit Gravity") {
                        NSApplication.shared.terminate(self)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                    .buttonStyle(.plain)
                    .font(.system(size: 14))
                    Spacer()
                    Text("⌘ Q")
                        .font(.system(size: 12))
                        .opacity(0.5)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(isQuitHovered ? Color("MenuBarButtonColor") : .clear)
                        .padding(-4)
                )
                .onHover { hovering in
                    isQuitHovered = hovering
                }

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
