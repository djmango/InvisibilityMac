//
//  OnboardingAccountView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import ConfettiSwiftUI
import SwiftUI

struct OnboardingAccountView: View {
    private var callback: () -> Void

    @ObservedObject private var userManager = UserManager.shared

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
    }

    var body: some View {
        VStack(alignment: .center) {
            SettingsUserCardView()

            Button(action: callback) {
                VStack {
                    Image(systemName: "arrowshape.right.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                }
                .padding()
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white, lineWidth: 2)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .transition(
                .asymmetric(
                    insertion: .movingParts.move(
                        angle: .degrees(270)
                    ).combined(with: .movingParts.blur).combined(with: .opacity),
                    removal: .movingParts.blur.combined(with: .opacity)
                )
            )
            .conditionalEffect(.repeat(.jump(height: 10), every: .seconds(3)), condition: true)
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    Color.white
                        .opacity(0.30)
                )
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(radius: 2)
        .visible(if: userManager.user != nil)
        .padding(.top, 20)
        .confettiCannon(counter: $userManager.confettis)

        // Sign up button
        Button(action: {
            userManager.signup()
        }) {
            VStack {
                Text("Complete your Account")
                    .font(Font.custom("SF Pro Rounded", size: 30))
                    .foregroundColor(.white)
            }
            .padding()
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
        .transition(
            .asymmetric(
                insertion: .movingParts.move(
                    angle: .degrees(270)
                ).combined(with: .movingParts.blur).combined(with: .opacity),
                removal: .movingParts.blur.combined(with: .opacity)
            )
        )
        .conditionalEffect(.repeat(.jump(height: 10), every: .seconds(3)), condition: true)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .visible(if: userManager.user == nil)
    }
}
