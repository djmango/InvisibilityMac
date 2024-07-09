//
//  SettingsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import KeyboardShortcuts
import LaunchAtLogin
import OSLog
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "SettingsView")
    let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    @AppStorage("animateButtons") private var animateButtons = true
    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("onboardingViewed") private var onboardingViewed = false
    @AppStorage("shortcutHints") private var shortcutHints = true
    @AppStorage("showMenuBar") private var showMenuBar: Bool = true
    @AppStorage("llmModelName") public var llmModel = LLMModelRepository.shared.models[0].id
    @AppStorage("dynamicLLMLoad") private var dynamicLLMLoad = false

    // Selected Shortcuts
    @AppStorage("showNewChat") private var showNewChat: Bool = true
    @AppStorage("showScreenshot") private var showScreenshot: Bool = false
    @AppStorage("showSidekick") private var showSidekick: Bool = true
    @AppStorage("showHistory") private var showHistory: Bool = true
    @AppStorage("showMemory") private var showMemory: Bool = true
    @AppStorage("showSettings") private var showSettings: Bool = true
    @AppStorage("showMicrophone") private var showMicrophone: Bool = true
    @AppStorage("showSwitchSides") private var showSwitchSides: Bool = false
    
    // TODO: func to reset to default settings

    @State private var showingExporter = false
    @State private var document: TextDocument = TextDocument(text: "")

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: SettingsViewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                VStack {
                    // User profile pic and login/logout button
                    SettingsUserCardView()
                        .visible(if: viewModel.user != nil)
                    
                    Button(action: {
                        viewModel.login()
                    }) {
                        Text("Login")
                    }
                    .buttonStyle(.bordered)
                    .visible(if: viewModel.user == nil, removeCompletely: true)
                }
                .padding(.top, 20)

                
                HStack {
                    Text("Model:")
                    
                    Picker("", selection: $llmModel) {
                        ForEach(viewModel.availableLLMModels, id: \.self) { model in
                            Text(model.human_name).tag(model.human_name)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .frame(maxWidth: 300)
                .padding(.top, 32)
                .padding(.bottom, 8)

                
                Divider()
                    .padding(.horizontal, 30)
                
                VStack (spacing: 12) {
                    generalSettingsMenu
                    shortcutsMenu
                    betaFeaturesMenu
                }
                .padding(.vertical, 20)

                Divider()
                    .padding(.horizontal, 30)
                    .padding(.bottom, 12)

                // Account
                Grid {
                    GridRow {
                        Button("Reset Onboarding") {
                            viewModel.startOnboarding()
                        }
                        .buttonStyle(.bordered)

                        Button("Export Chat") {
                            let text = viewModel.getExportChatText()
                            document = TextDocument(text: text)
                            showingExporter = true
                        }
                        .buttonStyle(.bordered)
                    }

                    GridRow {
                        Button("Check for Updates") {
                            viewModel.checkForUpdates()
                        }
                        .buttonStyle(.bordered)

                        Button("Feedback") {
                            if let url = URL(string: "mailto:support@i.inc") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()

                // Footer
                HStack {
                    Button("Acknowledgments") {
                        if let url = URL(string: "https://github.com/InvisibilityInc/Invisibility/tree/master/LICENSES") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)

                    Button("Privacy") {
                        if let url = URL(string: "https://i.inc/privacy") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                }

                Image("MenuBarIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .padding(.bottom, -5)
                    .onTapGesture {
                        if let url = URL(string: "https://invisibility.so") {
                            NSWorkspace.shared.open(url)
                        }
                    }

                HStack(spacing: 0) {
                    Text("Founded by ")
                        .font(.headline)
                    Text("Sulaiman Ghori")
                        .font(.headline)
                        .onTapGesture {
                            if let url = URL(string: "https://x.com/sulaimanghori") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    Text(" and ")
                        .font(.headline)
                    Text("Tye Daniel")
                        .font(.headline)
                        .onTapGesture {
                            if let url = URL(string: "https://x.com/TyeDan") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                }

                Text("© 2024 Invisibility, Inc. All rights reserved. Version \(bundleVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
            }
        }
        .scrollIndicators(.never)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .overlay(
            VStack {
                HStack {
                    Button(action: {
                        _ = viewModel.changeView(to: .chat)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .padding()

                    Spacer()
                }
                Spacer()
            }
        )
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .padding(.bottom, 3)
        .fileExporter(
            isPresented: $showingExporter,
            document: document,
            contentType: .plainText,
            defaultFilename: "invisibility.txt"
        ) { result in
            switch result {
            case let .success(url):
                logger.info("Saved to \(url)")
            case let .failure(error):
                logger.error(error.localizedDescription)
            }
        }
    }
    
    // General Settings
    var generalSettingsMenu: some View {
        Collapsible(collapsed: true, label: "General Settings", content: {
            LazyVGrid(columns: [GridItem(), GridItem()], alignment: .leading, content: {
                
                Text("Toggle Invisibility:")
                KeyboardShortcuts.Recorder(for: .summon)
                
                Text("Screenshot:")
                KeyboardShortcuts.Recorder(for: .screenshot)
                
                LaunchAtLogin.Toggle("Launch at Login")
                    .toggleStyle(.checkbox)
                    .padding(.top, 12)
                
                Toggle("Show on Menu Bar", isOn: $showMenuBar)
                    .toggleStyle(.checkbox)
                    .padding(.top, 12)
            })
        })
    }
    
    // Shortcuts
    var shortcutsMenu: some View {
        Collapsible(collapsed: true, label: "Shortcuts", content: {
            VStack (alignment: .leading) {
                Text("Choose which shortcuts appear in you chat menu bar")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 6)
                
                LazyVGrid (columns: [GridItem(), GridItem()], alignment: .leading, content: {
                    Toggle("New Chat", isOn: $showNewChat)
                        .toggleStyle(.checkbox)
                    
                    // Maybe move
                    Toggle("Microphone", isOn: $showMicrophone)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Screenshot", isOn: $showScreenshot)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Sidekick", isOn: $showSidekick)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Chat History", isOn: $showHistory)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Memory", isOn: $showMemory)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Settings", isOn: $showSettings)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Switch Sides", isOn: $showSwitchSides)
                        .toggleStyle(.checkbox)
                })
                
                Toggle("Show Shortcut Hints", isOn: $shortcutHints)
                    .toggleStyle(.switch)
                    .gridCellColumns(2)
                    .padding(.top, 12)
            }
        })
    }
    
    // Beta Features
    var betaFeaturesMenu: some View {
        Collapsible(collapsed: true, label: "Beta Features", content: {
            VStack (alignment: .leading) {
                Text("Turn on beta fatures")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 6)
                
                LazyVGrid (columns: [GridItem(), GridItem()], alignment: .leading, content: {
                    
                    Toggle("Animate Buttons", isOn: $animateButtons)
                        .toggleStyle(.checkbox)
                    
                    Toggle("All LLMs", isOn: $dynamicLLMLoad)
                        .toggleStyle(.checkbox)
                        .onChange(of: dynamicLLMLoad) {
                            Task { @MainActor in await viewModel.loadDynamicModels() }
                        }
                })
            }
        })
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)
        return .init(regularFileWithContents: data!)
    }
}

#Preview {
    SettingsView()
}
