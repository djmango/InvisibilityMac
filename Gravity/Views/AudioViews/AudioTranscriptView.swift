//
//  AudioTranscriptView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import SwiftUI

struct AudioTranscriptView: View {
    var messages: [String]

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                    HStack {
                        Text(message)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(index % 2 == 0 ? Color.gray.opacity(0.2) : Color.clear)
                            .onHover { _ in
                                // Handle hover state changes if needed
                            }
                        // if NSApp.currentEvent?.type == NSEvent.EventType.leftMouseEntered {
                        //     Button(action: {
                        //         // Handle play action
                        //     }) {
                        //         Image(systemName: "play.circle")
                        //             .resizable()
                        //             .frame(width: 20, height: 20)
                        //     }
                        //     .buttonStyle(PlainButtonStyle())
                        //     .frame(width: 20, height: 20, alignment: .trailing)
                        //     .padding(.trailing)
                        // }
                    }
                }
            }
        }
    }
}
