import os
import SwiftUI
import ViewState

struct AppView: View {
    private let logger = Logger(subsystem: "ai.grav.app", category: "AppView")

    @EnvironmentObject private var imageViewModel: ImageViewModel
    @ObservedObject private var alertViewModel = AlertViewModel.shared

    @AppStorage("onboardingViewed") private var onboardingViewed = false

    var body: some View {
        GeometryReader { geometry in
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

                                Text("No chat selected")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding()

                                Spacer()

                                Button(action: {
                                    CommandViewModel.shared.addChat()
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
                                    CommandViewModel.shared.addChat()
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

                    if let (image, frame) = imageViewModel.getImage() {
                        ExpandedImageView(nsImage: image, originalFrame: frame, geometry: geometry, onDismiss: {
                            imageViewModel.clearImage()
                        })
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
}
