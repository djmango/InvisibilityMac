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
            AsyncImage(url: URL(string: userManager.user?.profilePictureUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .padding(10)
            } placeholder: {
                ProgressView()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            .visible(if: userManager.user?.profilePictureUrl != nil)

            Text("\(userManager.user?.firstName ?? "") \(userManager.user?.lastName ?? "")")
                .font(.title3)
                .foregroundColor(.white)
                .visible(if: userManager.user?.firstName != nil || userManager.user?.lastName != nil)

            Text(userManager.user?.email ?? "")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.bottom, 15)

            Text("Invisibility Plus")
                .font(.caption)
                .italic()
                .foregroundColor(.white)
                .visible(if: userManager.isPaid)

            Button(action: {
                if userManager.isPaid {
                    callback()
                } else {
                    Task {
                        await userManager.checkPaymentStatus()
                    }
                    userManager.pay()
                }
            }) {
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

            Text("Subscription required")
                .font(.caption)
                .italic()
                .foregroundColor(.white)
                .visible(if: !userManager.isPaid && userManager.user != nil)
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
