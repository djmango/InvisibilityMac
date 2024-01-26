//
//  NewChatView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/25/24.
//

import os
import SwiftUI

struct NewChatView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "NewChatView")

    @State private var isDragActive: Bool = false

    var body: some View {
        VStack {
            Spacer()

            Button(action: {
                _ = CommandViewModel.shared.addChat()
            }) {
                Text("New Chat")
                    .font(.system(size: 18))
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 200, height: 50)
            .buttonStyle(.plain)
            .background(Color(red: 255 / 255, green: 105 / 255, blue: 46 / 255, opacity: 1))
            .cornerRadius(10)
            .padding()
            .focusable(false)
            .onTapGesture(perform: {
                _ = CommandViewModel.shared.addChat()
            })
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Spacer()

            // if OllamaViewModel.shared.mistralDownloadProgress < 1.0,
            //    OllamaViewModel.shared.mistralDownloadProgress > 0.0
            // {
            //     Text("\(Int(OllamaViewModel.shared.mistralDownloadProgress * 100))%")
            //         .font(.title)
            //         .bold()
            //         .foregroundColor(.white)

            //     ProgressView(value: OllamaViewModel.shared.mistralDownloadProgress, total: 1.0)
            //         .accentColor(.accentColor)
            //         .scaleEffect(x: 1, y: 2, anchor: .center)
            //         .frame(width: 400)
            //         .conditionalEffect(
            //             .repeat(
            //                 .glow(color: .white, radius: 10),
            //                 every: 3
            //             ), condition: true
            //         )

            //     Spacer()
            // }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
                .opacity(isDragActive ? 1 : 0)
        )
        .border(isDragActive ? Color.blue : Color.clear, width: 5)
        .onDrop(of: [.fileURL], isTargeted: $isDragActive) { providers in
            handleDrop(providers: providers)
        }
    }

    @MainActor
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    guard error == nil else {
                        logger.error("Error loading item: \(error!)")
                        return
                    }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        // Process the file URL
                        let chat = CommandViewModel.shared.addChat()
                        if let chat {
                            let messageViewModel = MessageViewModel(chat: chat)
                            messageViewModel.handleFile(url: url)
                        }
                    }
                }
            }
            // Handle images (e.g., from screenshot thumbnail)
            else {
                logger.error("Unsupported item provider type")
            }
        }
        return true
    }
}
