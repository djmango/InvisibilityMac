//
//  OnboardingDownloadView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import os
import SwiftUI

struct OnboardingDownloadView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "OnboardingDownloadView")
    @State private var showDeleteAllDataAlert: Bool = false

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

                if OllamaViewModel.shared.mistralDownloadStatus != .complete {
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
                } else {
                    Spacer()
                    Text("Download complete!")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                }

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
                .background(.accent)
                .opacity(OllamaViewModel.shared.mistralDownloadStatus == .complete ? 1.0 : 0.5)
                .cornerRadius(25)
                .padding()
                .focusable(false)
                .disabled(OllamaViewModel.shared.mistralDownloadStatus != .complete)
                .onTapGesture {
                    if OllamaViewModel.shared.mistralDownloadStatus == .complete {
                        callback()
                    }
                }
                .onHover { hovering in
                    if hovering, OllamaViewModel.shared.mistralDownloadStatus == .complete {
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
                            OllamaViewModel.shared.wipeOllama()

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
                await OllamaViewModel.shared.pullModels()
            }
        }
    }
}
