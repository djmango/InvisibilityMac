import DockProgress
import os
import SettingsKit
import Sparkle
import SwiftData
import SwiftUI
import TelemetryClient

@main
struct GravityApp: App {
    private let logger = Logger(subsystem: "ai.grav.app", category: "GravityApp")

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var updater: SPUUpdater

    @StateObject private var updaterViewModel: UpdaterViewModel

    @AppStorage("analytics") var analytics: Bool = true {
        didSet {
            if analytics != true {
                TelemetryManager.send("TelemetryDisabled")
            } else {
                TelemetryManager.send("TelemetryEnabled")
            }
        }
    }

    @AppStorage("userIdentifier") private var userIdentifier: String = ""
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    init() {
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        updater = updaterController.updater

        let updaterViewModel = UpdaterViewModel(updater: updater)
        _updaterViewModel = StateObject(wrappedValue: updaterViewModel)

        SharedModelContainer.shared = SharedModelContainer()

        if analytics {
            if userIdentifier.isEmpty {
                userIdentifier = UUID().uuidString
            }

            let telemetryConfig = TelemetryManagerConfiguration(
                appID: "3F0E42B4-8F78-4047-B648-6C262EB5D9BE"
            )
            TelemetryManager.initialize(with: telemetryConfig)
            TelemetryManager.updateDefaultUser(to: userIdentifier)

            TelemetryManager.send("ApplicationLaunched")
        }

        Task {
            await WhisperManager.shared.setup()
        }
        Task {
            await LLMManager.shared.setup()
        }

        DockProgress.style = .pie(color: .accent)
    }

    var body: some Scene {
        Window("Gravity", id: "master") {
            AppView()
                .environmentObject(updaterViewModel)
                .pasteDestination(for: URL.self) { urls in
                    guard let url = urls.first else { return }
                    MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat).handleFile(url: url)
                }
                .onAppear {
                    Task {
                        if await !ScreenRecorder.shared.canRecord {
                            logger.error("Screen recording is not available")
                        } else {
                            logger.info("Screen recording is available")
                        }
                    }
                }
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(SharedModelContainer.shared.modelContainer)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updater.checkForUpdates()
                }
                .disabled(!updaterViewModel.canCheckForUpdates)
            }

            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    _ = CommandViewModel.shared.addChat()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open File") {
                    MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat).openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .textEditing) {
                ChatContextMenu(for: CommandViewModel.shared.selectedChat)
            }
        }
        .settings {
            SettingsTab(.new(title: "General", icon: .gearshape), id: "general") {
                SettingsSubtab(.noSelection, id: "general") {
                    GeneralSettingsView().modelContext(SharedModelContainer.shared.mainContext)
                }
            }
            .frame(width: 550, height: 200)
            SettingsTab(.new(title: "Advanced", icon: .gearshape2), id: "advanced") {
                SettingsSubtab(.noSelection, id: "advanced") { AdvancedSettingsView() }
            }
            .frame(width: 550, height: 200)
            SettingsTab(.new(title: "About", icon: .info), id: "about") {
                SettingsSubtab(.noSelection, id: "about") {
                    AboutSettingsView()
                        .environmentObject(updaterViewModel)
                }
            }
            .frame(width: 550, height: 200)
        }
        MenuBarExtra("Gravity", image: "MenuBarIcon", isInserted: $showMenuBarExtra) {
            // Button("New Chat") {
            //     _ = CommandViewModel.shared.addChat()
            // }
            // .keyboardShortcut("n", modifiers: .command)

            // Button(action: {
            //     MessageViewModelManager.shared.viewModel(for: CommandViewModel.shared.selectedChat).openFile()
            // }) {
            //     Label("Open File", systemImage: "folder")
            // }
            // .keyboardShortcut("o", modifiers: .command)

            Button("Record Audio") {
                // MessageViewModelManager.shared.currentViewModel().recordAudio()
                print("Record Audio")
                Task {
                    if await ScreenRecorder.shared.canRecord {
                        await ScreenRecorder.shared.start()
                    } else {
                        AlertManager.shared.doShowAlert(title: "Screen Recording Permission Grant", message: "Gravity has not been granted permission to record the screen. Please enable this permission in System Preferences > Security & Privacy > Screen & System Audio Recording.")
                        // Open the System Preferences app to the Screen Recording settings.
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
                    }
                }
            }
            .hide(if: ScreenRecorder.shared.isRunning)
            .keyboardShortcut("r", modifiers: .command)

            Button("Stop Recording") {
                Task {
                    await ScreenRecorder.shared.stop()
                }
            }
            .hide(if: !ScreenRecorder.shared.isRunning)

            // AudioLevelsView(audioLevelsProvider: screenRecorder.audioLevelsProvider)
            // ProgressView(value: ScreenRecorder.shared.audioLevelsProvider.audioLevels.level)

            Divider()

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 5)

            Button("Check for Updates") {
                updater.checkForUpdates()
            }
            .disabled(!updaterViewModel.canCheckForUpdates)

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Gravity") {
                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut("q", modifiers: .command)

            Divider()
        }
    }
}
