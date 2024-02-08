//
//  OnboardingDownloadView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import OSLog
import SwiftUI

struct OnboardingDownloadView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "OnboardingDownloadView")
    @State private var showDeleteAllDataAlert: Bool = false

    @ObservedObject private var llmDownloader = LLMManager.shared.downloader

    private var callback: () -> Void

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
    }

    var body: some View {
        ZStack {
            VStack {
                Spacer()

                Image("GravityAppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .conditionalEffect(
                        .repeat(
                            .shine(duration: 0.3),
                            every: 3
                        ), condition: true
                    )

                if llmDownloader.state == .downloading {
                    Text("Downloading models...")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)

                    Text("This may take a few minutes (it's the size of a movie)")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.gray)

                    Spacer()

                    Text("\(Int(llmDownloader.progress * 100))%")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)

                    ProgressView(value: llmDownloader.progress, total: 1.0)
                        .accentColor(.accentColor)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .frame(width: 400)
                        .conditionalEffect(
                            .repeat(
                                .glow(color: .white, radius: 10),
                                every: 3
                            ), condition: true
                        )
                } else {
                    Spacer()
                    Text("Download complete!")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: continueToApp) {
                    Text("Start Gravity")
                        .font(.system(size: 18))
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .frame(width: 200, height: 50)
                .buttonStyle(.plain)
                .background(.accent)
                .cornerRadius(25)
                .padding()
                .focusable(false)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showDeleteAllDataAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding()
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .confirmationDialog(
                        AppMessages.wipeModelsTitle,
                        isPresented: $showDeleteAllDataAlert
                    ) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            // Wipe models
                            LLMManager.shared.wipe()
                            WhisperManager.shared.wipe()

                            // Restart app
                            NSApplication.shared.terminate(self)
                        }
                    } message: {
                        Text(AppMessages.wipeModelsMessage)
                    }
                    .dialogSeverity(.critical)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                await LLMManager.shared.setup()
            }
        }
    }

    func continueToApp() {
        if llmDownloader.state == .completed {
            callback()
        } else {
            AlertManager.shared.doShowAlert(
                title: "Download not complete",
                message: "Please wait for the download to complete before starting Gravity. If the download is stuck, please restart the app."
            )
        }
    }
}
