//
//  LoginCardView.swift
//  Invisibility
//
//  Created by Rahul Gupta on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct LoginCardView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var isLoggingIn = false
    @State private var isHovering = false
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        VStack {
            Spacer().frame(height: geometry.size.height * 0.85)

            VStack(spacing: 15) {
                Text("Welcome to Invisibility 💙")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Please log in to continue")
                    .font(.body)
                    .foregroundColor(.gray)

                Button(action: {
                    isLoggingIn = true
                    UserManager.shared.login()
                }) {
                    Text("Log In")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 28)
                        .background(Color.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(nsColor: .separatorColor))
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .shadow(radius: 2)
                .disabled(isLoggingIn)
                .onHover { hovering in
                    isHovering = hovering
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }

                if isLoggingIn {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(height: 20)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(nsColor: .separatorColor))
            )
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
            )
            .cornerRadius(16)
            .frame(width: geometry.size.width * 0.8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
