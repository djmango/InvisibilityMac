//
//  OnboardingIntroView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import Pow
import SwiftUI

struct OnboardingIntroView: View {
    private var callback: () -> Void

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
    }

    var body: some View {
        VStack {
            Spacer()

            Image("GravityAppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .conditionalEffect(
                    .repeat(
                        .shine(duration: 0.3),
                        // .glow(color: .white, radius: 20),
                        // .jump(height: 10),
                        // .pulse(shape: Circle(), count: 3),
                        // .wiggle(rate: .fast),
                        every: 3
                    ), condition: true
                )

            Text("Gravity")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding()

            Text("Your personal AI assistant")
                .font(.title)
                .bold()
                .foregroundColor(.gray)

            Spacer()

            Button(action: callback) {
                HStack {
                    Spacer()
                    Text("Get started")
                        .font(.system(size: 18))
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)

                    // Black line in the middle
                    Rectangle()
                        .frame(width: 2, height: 30)
                        .cornerRadius(1)
                        .foregroundColor(.black.opacity(0.1))
                        .padding(.trailing, 10)

                    Image(systemName: "chevron.right")
                        .font(.title)
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(width: 200, height: 50)
            }
            .buttonStyle(.plain)
            .background(Color(red: 255 / 255, green: 105 / 255, blue: 46 / 255, opacity: 1))
            .cornerRadius(25)
            .padding()
            .focusable(false)
            .onTapGesture(perform: callback)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
}
