//
//  AudioWidgetView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import SwiftData
import SwiftUI

struct AudioWidgetView: View {
    private var audio: Audio

    init(audio: Audio) {
        self.audio = audio
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color("WidgetColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                )

            HStack {
                Spacer()

                Image(systemName: "waveform.badge.mic")
                    .resizable()
                    .foregroundColor(.white.opacity(0.6))
                    .aspectRatio(contentMode: .fit)
                    .padding(12)

                VStack(alignment: .center) {
                    Spacer()

                    // If we are done generating, show the name of the audio
                    if audio.completed {
                        let name = audio.name.isEmpty ? "Generating title.." : audio.name
                        Text(name)
                            .font(.title2)
                            .padding()
                            .bold()
                    }
                    // Otherwise, show the last segment text with an animation on change
                    else {
                        Text(audio.lastSegmentText ?? "")
                            .font(.title3)
                            .padding()
                            .bold()
                            .italic()
                    }

                    Spacer()

                    ProgressView(value: audio.progress, total: 1.0)
                        .accentColor(.accentColor)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .cornerRadius(10)
                        .conditionalEffect(
                            .repeat(
                                .glow(color: .white, radius: 10),
                                every: 3
                            ), condition: !audio.error && !audio.completed
                        )
                        .hide(if: audio.completed, removeCompletely: true)
                }

                Spacer()
            }
        }
        .frame(width: 450, height: 80)
    }
}
