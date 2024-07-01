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
            VStack {
                Text("Welcome to Invisibility 💙")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Please log in to continue")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    isLoggingIn = true
                    UserManager.shared.login()
                }) {
                    Text("Log In")
                        .font(.system(size: 20, weight: .bold))
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
            .frame(height: 200)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(nsColor: .separatorColor))
            )
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
            )
            .cornerRadius(16)
            .frame(maxWidth: 400)
            .frame(maxHeight: .infinity, alignment: .bottom)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
