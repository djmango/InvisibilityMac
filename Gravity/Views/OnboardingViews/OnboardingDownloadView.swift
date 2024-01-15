//
//  OnboardingDownloadView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import SwiftUI

struct OnboardingDownloadView: View {
    // @ObservedObject var viewModel: OllamaViewModel

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
                        every: 3
                    ), condition: true
                )

            Text("Downloading models...")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            Text("This may take a few minutes (it's the size of a movie) (it's worth it)")
                .font(.subheadline)
                .bold()
                .foregroundColor(.gray)

            Spacer()

            Text("\(Int(OllamaViewModel.shared.mistralDownloadProgress * 100))%")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            ProgressView(value: OllamaViewModel.shared.mistralDownloadProgress, total: 1.0)
                .accentColor(.accentColor)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .frame(width: 400)
                .conditionalEffect(
                    .repeat(
                        .glow(color: .white, radius: 10),
                        every: 3
                    ), condition: true
                )

            Spacer()

            Button(action: callback) {
                Text("Start Gravity")
                    .font(.system(size: 18))
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 200, height: 50)
            .buttonStyle(.plain)
            .background(Color(red: 255 / 255, green: 105 / 255, blue: 46 / 255, opacity: 1))
            .cornerRadius(25)
            .padding(.top, 10)
            .focusable(false)
            .onTapGesture(perform: callback)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
