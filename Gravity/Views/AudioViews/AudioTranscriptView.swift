//
//  AudioTranscriptView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import SwiftUI

struct SegmentView: View {
    private let index: Int
    private let segment: AudioSegment

    @ObservedObject private var audioPlayerViewModel = AudioPlayerViewModel.shared

    @State var isCurrentSegment = false
    @State var isHoveringSegment = false

    init(index: Int, segment: AudioSegment) {
        self.index = index
        self.segment = segment
    }

    var body: some View {
        ZStack {
            // Background zebra stripes.
            // If playing at current time, highlight the current segment.

            // let currentTimeInMillis = Int(audioPlayerViewModel.player?.currentTime ?? 0) * 1000

            // if currentTimeInMillis > (segment.startTime),
            //    currentTimeInMillis < (segment.endTime)
            // {
            //     // Highlight the current segment
            //     Color.blue.opacity(0.2)
            //         .onAppear {
            //             isCurrentSegment = true
            //         }
            //         .onDisappear {
            //             isCurrentSegment = false
            //         }
            // } else {
            if index % 2 == 0 {
                Color.gray.opacity(0.2)
            } else {
                Color.clear
            }
            // }

            HStack {
                Text(segment.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                Spacer()

                // Audio play button to skip to the segment.
                if isHoveringSegment {
                    Button(action: {
                        seek(to: segment.startTime)
                    }) {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.accessoryBar)
                    .padding(.trailing, 8)
                }
            }
            .onHover { isHovering in
                if isHovering {
                    NSCursor.pointingHand.push()
                    isHoveringSegment = true
                } else {
                    NSCursor.pop()
                    isHoveringSegment = false
                }
            }
            .onTapGesture {
                seek(to: segment.startTime)
            }
        }
    }

    private func seek(to milliseconds: Int) {
        let seconds = TimeInterval(milliseconds / 1000)
        audioPlayerViewModel.seek(to: seconds)
    }
}

struct AudioTranscriptView: View {
    private var audio: Audio?

    @ObservedObject private var audioPlayerViewModel = AudioPlayerViewModel.shared

    init(audio: Audio?) {
        self.audio = audio
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, spacing: 0) {
                if let audio {
                    ForEach(Array(audio.segments.enumerated()), id: \.offset) { index, segment in
                        SegmentView(index: index, segment: segment)
                    }
                }
            }
        }
    }
}
