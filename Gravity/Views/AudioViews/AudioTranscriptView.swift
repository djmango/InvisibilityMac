//
//  AudioTranscriptView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import SwiftUI

struct AudioTranscriptView: View {
    private var audio: Audio
    @Binding var isShowingAudioTranscript: Bool

    init(audio: Audio, isShowingAudioTranscript: Binding<Bool>) {
        self.audio = audio
        _isShowingAudioTranscript = isShowingAudioTranscript
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(audio.segments.enumerated()), id: \.offset) { index, segment in
                    HStack {
                        Text(segment.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(index % 2 == 0 ? Color.gray.opacity(0.2) : Color.clear)
                            .onHover { _ in
                                // Handle hover state changes if needed
                            }
                    }
                }
            }
        }
    }
}
