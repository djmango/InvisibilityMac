//
//  AboutSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import SwiftUI

struct AboutSettingsView: View {
    let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    @StateObject private var updaterViewModel = UpdaterViewModel.shared

    var body: some View {
        VStack {
            Spacer()
            Image("GravityLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)

            HStack(spacing: 0) {
                Text("Founded by ")
                    .font(.headline)
                Text("Sulaiman Ghori")
                    .font(.headline)
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://x.com/sulaimanghori") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                Text(" and ")
                    .font(.headline)
                Text("Tye Daniel")
                    .font(.headline)
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .onTapGesture {
                        if let url = URL(string: "https://x.com/TyeDan") {
                            NSWorkspace.shared.open(url)
                        }
                    }
            }

            HStack {
                Button("Feedback") {
                    if let url = URL(string: "mailto:sulaiman@grav.ai") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)

                Button("Acknowledgments") {
                    if let url = URL(string: "https://github.com/InvisibilityInc/Gravity/tree/master/LICENSES") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)

                Button("Check for Updates") {
                    updaterViewModel.updater.checkForUpdates()
                }
                .buttonStyle(.bordered)

                Button("Privacy") {
                    if let url = URL(string: "https://grav.ai/privacy") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 10)

            Spacer()

            Text("© 2024 Invisibility, Inc. All rights reserved. Version \(bundleVersion)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 10)

            Spacer()
        }
    }
}
