import os
import SwiftUI
import ViewState

struct AppView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AppView")

    @ObservedObject private var alertViewModel = AlertViewModel.shared

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        ZStack {
            if onboardingViewed {
                NavigationSplitView {
                    ChatSidebarListView()
                        .navigationSplitViewColumnWidth(min: 240, ideal: 240)
                } detail: {
                    if let selectedChat = CommandViewModel.shared.selectedChat {
                        MessageView(for: selectedChat)
                    } else {
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

                            if OllamaViewModel.shared.mistralDownloadProgress < 1.0,
                               OllamaViewModel.shared.mistralDownloadProgress > 0.0
                            {
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
                            }
                        }
                    }
                }

                .toolbar {
                    // ToolbarItem(placement: .primaryAction) {
                    //     Button(action: {
                    //         _ = CommandViewModel.shared.addChat()
                    //     }) {
                    //         Label("New Chat", systemImage: "square.and.pencil")
                    //     }
                    //     .buttonStyle(.accessoryBar)
                    //     .help("New Chat (⌘ + N)")
                    // }

                    // ToolbarItemGroup(placement: .automatic) {
                    //     Button(action: {
                    //         isRestarting = true
                    //         Task {
                    //             do {
                    //                 try await OllamaKit.shared.waitForAPI(restart: true)
                    //                 isRestarting = false
                    //             } catch {
                    //                 AlertViewModel.shared.doShowAlert(title: "Error", message: "Could not restart models. Please try again.")
                    //             }
                    //         }
                    //     }) {
                    //         Label("Restart Models", systemImage: "arrow.clockwise")
                    //             .rotationEffect(.degrees(isRestarting ? 360 : 0))
                    //             .animation(isRestarting ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRestarting)
                    //     }
                    //     .buttonStyle(.accessoryBar)
                    //     .help("Restart Models")

                    //     Button(action: {
                    //         if let chat = CommandViewModel.shared.getOrCreateChat() {
                    //             MessageViewModelManager.shared.viewModel(for: chat).openFile()
                    //         } else {
                    //             logger.error("Could not create chat")
                    //         }
                    //     }) {
                    //         Label("Open File", systemImage: "square.and.arrow.down")
                    //     }
                    //     .buttonStyle(.accessoryBar)
                    //     .help("Open File (⌘ + O)")
                    // }
                    ToolbarView()
                }
            } else {
                OnboardingView()
            }
        }
        .alert(isPresented: $alertViewModel.showAlert) {
            Alert(
                title: Text(alertViewModel.alertTitle),
                message: Text(alertViewModel.alertMessage),
                dismissButton: .default(Text(alertViewModel.alertDismissText))
            )
        }
    }
}
