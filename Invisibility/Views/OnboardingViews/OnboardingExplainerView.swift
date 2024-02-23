//
//  OnboardingExplainerView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import SwiftUI

struct OnboardingExplainerView: View {
    private var callback: () -> Void

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Upload") {
                    // Upload action
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(15)

                Spacer()

                Button("Chat") {
                    // Chat action
                }
                .foregroundColor(.white)

                Spacer()

                Button("Privacy") {
                    // Privacy action
                }
                .foregroundColor(.white)
            }
            .padding()

            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "waveform.path")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Audio")
                }
                .frame(width: 120, height: 120)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Image")
                }
                .frame(width: 120, height: 120)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
            .foregroundColor(.white)

            Text("Upload audio, video, image and text files")
                .foregroundColor(.gray)

            Spacer()

            Button(action: callback) {
                Text("Continue")
                    .font(.system(size: 18))
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 200, height: 50)
            .buttonStyle(.plain)
            .background(Color.red)
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
