//
//  MessageLoaderView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct MessageLoaderView: View {
    @State var isAnimating: Bool = false
    let timing: Double

    let maxCounter: Int = 20

    let frame: CGSize
    let primaryColor: Color

    init(color: Color = .black, size: CGFloat = 50, speed: Double = 0.5) {
        timing = speed * 2
        frame = CGSize(width: size * 2, height: size)
        primaryColor = color
    }

    var body: some View {
        ZStack {
            HStack(spacing: frame.width / 40) {
                ForEach(0 ..< maxCounter) { index in

                    Circle()
                        .fill(primaryColor)
                        .offset(y: isAnimating ? frame.height / 6 : -frame.height / 6)
                        .animation(
                            Animation
                                .easeInOut(duration: timing)
                                .repeatForever(autoreverses: true)
                                .delay(timing / Double(maxCounter) * Double(index))
                        )
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.8)
                        .animation(Animation.easeInOut(duration: timing).repeatForever(autoreverses: true))
                }
            }

            HStack(spacing: frame.width / 40) {
                ForEach(0 ..< maxCounter) { index in

                    Circle()
                        .fill(primaryColor)
                        .offset(y: isAnimating ? -frame.height / 6 : frame.height / 6)
                        .animation(
                            Animation
                                .easeInOut(duration: timing)
                                .repeatForever(autoreverses: true)
                                .delay(timing / Double(maxCounter) * Double(index))
                        )
                        .scaleEffect(isAnimating ? 0.8 : 1.0)
                        .opacity(isAnimating ? 0.8 : 1.0)
                        .animation(Animation.easeInOut(duration: timing).repeatForever(autoreverses: true))
                }
            }
        }
        .frame(width: frame.width, height: frame.height, alignment: .center)
        .onAppear {
            isAnimating.toggle()
        }
    }
}
