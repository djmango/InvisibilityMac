//
//  OnboardingIntroView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import Pow
import SwiftUI

struct OnboardingIntroView: View {
    @State private var animationStep = 0
    @State private var showSub = false

    private var callback: () -> Void

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
    }

    var body: some View {
        VStack {
            switch animationStep {
            case 0:
                Text("Shh im not here")
                    .opacity(0)

            case 1:
                Image("LogoWhite")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding()
                    .transition(
                        .asymmetric(
                            insertion: .movingParts.move(
                                angle: .degrees(270)
                            ).combined(with: .movingParts.blur).combined(with: .opacity),
                            removal: .movingParts.blur.combined(with: .opacity)
                        )
                    )

            case 2:
                Text("Meet your invisible AI")
                    .font(Font.custom("SF Pro Rounded", size: 70))
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .transition(.asymmetric(
                        insertion: .movingParts.blur.combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                        removal: .movingParts.blur.combined(with: .opacity).combined(with: .scale(scale: 0.8))
                    ))

                if showSub {
                    // Boxed arrow for next step
                    Button(action: {
                        callback()
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
                    .opacity(0.85)
                    .buttonStyle(.plain)
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
                }

            default:
                Text("Shh im not here")
                    .opacity(0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1.5)) {
                    animationStep = 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeIn(duration: 1)) {
                        animationStep = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(.timingCurve(0.4, 0, 0.4, 1, duration: 2.8)) {
                            animationStep = 2
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showSub = true
                        }
                    }
                }
            }
        }
    }
}
