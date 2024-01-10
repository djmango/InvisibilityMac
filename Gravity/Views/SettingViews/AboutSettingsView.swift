//
//  AboutSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import SwiftUI

struct AboutSettingsView: View {
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
                    // .foregroundColor(.blue)
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
                    // .foregroundColor(.blue)
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
                    if let url = URL(string: "https://grav.ai") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)

                Button("Acknowledgments") {
                    if let url = URL(string: "https://grav.ai/tos") {
                        NSWorkspace.shared.open(url)
                    }
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
            // All rights reserved.
            Text("© 2024 Invisibility, Inc. All rights reserved.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
        }
    }
}
