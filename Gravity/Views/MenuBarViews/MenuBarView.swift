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

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                EventsView()

                Divider()

                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Check for Updates") {
                    updaterViewModel.updater.checkForUpdates()
                }
                .disabled(!updaterViewModel.canCheckForUpdates)
                .buttonStyle(.accessoryBar)
                .foregroundColor(.primary)
                .selectionDisabled()

                SettingsLink {
                    Text("Settings")
                }
                .keyboardShortcut(",", modifiers: .command)
                .buttonStyle(.accessoryBar)
                .foregroundColor(.primary)
                .selectionDisabled()

                Divider()

                Button("Quit Gravity") {
                    NSApplication.shared.terminate(self)
                }
                .keyboardShortcut("q", modifiers: .command)
                .buttonStyle(.accessoryBar)
                .foregroundColor(.primary)
                .selectionDisabled()

                Divider()
            }
        }
        .padding(.horizontal, 8)
        .focusable(false)
    }
}

// struct HoverButtonStyle: ButtonStyle {
//     func makeBody(configuration: Configuration) -> some View {
//         configuration.label
//             .foregroundColor(.primary)
//             .background(configuration.isPressed ? Color.accentColor : Color.clear) // Pressed state
//             .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
//             .foregroundColor(.primary)
//             // Use .overlay with RoundedRectangle for macOS to create a borderless look
//             .overlay(
//                 RoundedRectangle(cornerRadius: 5) // Adjust cornerRadius to fit your design
//                     .stroke(Color.clear, lineWidth: 0) // No border
//             )
//             .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
//             .background(HoverBackground(isHovered: configuration.))
//     }
// }

// struct HoverBackground: View {
//     @State var isHovered = false

//     var body: some View {
//         RoundedRectangle(cornerRadius: 5)
//             .fill(isHovered ? Color.accentColor : Color.clear)
//     }
// }

#Preview {
    MenuBarView()
}
