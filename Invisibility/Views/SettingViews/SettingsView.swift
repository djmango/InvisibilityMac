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
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "SettingsView")
    let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

    @AppStorage("animateButtons") private var animateButtons = true
    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("betaFeatures") private var betaFeatures = false
    @AppStorage("onboardingViewed") private var onboardingViewed = false
    @AppStorage("llmModel") private var llmModel = LLMModels.claude3_opus.human_name
    @AppStorage("shortcutHints") private var shortcutHints = true
    @AppStorage("showMenuBar") private var showMenuBar: Bool = true

    private var llmManager = LLMManager.shared

    @State private var showingExporter = false
    @State private var document: TextDocument = TextDocument(text: "")

    @ObservedObject private var userManager = UserManager.shared
    private var updaterViewModel = UpdaterViewModel.shared

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .menu, blendingMode: .withinWindow, cornerRadius: 16)

            VStack(alignment: .center, spacing: 10) {
                Spacer()
                // User profile pic and login/logout button
                VStack(alignment: .center) {
                    AsyncImage(url: URL(string: userManager.user?.profilePictureUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(colorScheme == .dark ? .white : .black, lineWidth: 2))
                            .padding(10)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(colorScheme == .dark ? .white : .black), lineWidth: 2))
                            .padding(10)
                    }
                    .visible(if: userManager.user?.profilePictureUrl != nil)

                    Text("\(userManager.user?.firstName ?? "") \(userManager.user?.lastName ?? "")")
                        .font(.title3)
                        .visible(if: userManager.user?.firstName != nil || userManager.user?.lastName != nil)

                    Text(userManager.user?.email ?? "")
                        .font(.caption)
                        .padding(.bottom, 15)

                    Text("Invisibility Plus")
                        .font(.caption)
                        .italic()
                        .visible(if: userManager.isPaid)

                    Button(action: {
                        UserManager.shared.manage()
                    }) {
                        Text("Manage")
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        UserManager.shared.logout()
                    }) {
                        Text("Logout")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("ChatButtonBackgroundColor"))
                        .stroke(colorScheme == .dark ? .white : .black, lineWidth: 0.5)
                )
                .shadow(radius: colorScheme == .dark ? 2 : 0)
                .visible(if: userManager.user != nil)

                Button(action: {
                    UserManager.shared.login()
                }) {
                    Text("Login")
                }
                .buttonStyle(.bordered)
                .visible(if: userManager.user == nil, removeCompletely: true)

                Spacer()

                Divider()
                    .padding(.horizontal, 80)

                Spacer()

                HStack {
                    Text("Toggle panel")
                    KeyboardShortcuts.Recorder(for: .summon)
                }

                HStack {
                    Text("Screenshot")
                    KeyboardShortcuts.Recorder(for: .screenshot)
                }

                Picker("", selection: $llmModel) {
                    Text(LLMModels.claude3_opus.human_name).tag(LLMModels.claude3_opus.human_name)
                    Text(LLMModels.claude3_sonnet.human_name).tag(LLMModels.claude3_sonnet.human_name)
                    Text(LLMModels.claude3_haiku.human_name).tag(LLMModels.claude3_haiku.human_name)
                    Text(LLMModels.gpt4.human_name).tag(LLMModels.gpt4.human_name)
                    Text(LLMModels.gemini_pro.human_name).tag(LLMModels.gemini_pro.human_name)
                    Text(LLMModels.perplexity_mixtral.human_name).tag(LLMModels.perplexity_mixtral.human_name)
                    Text(LLMModels.perplexity_sonar_online.human_name).tag(LLMModels.perplexity_sonar_online.human_name)
                    Text(LLMModels.groq_mixtral.human_name).tag(LLMModels.groq_mixtral.human_name)
                    Text(LLMModels.dbrx_together.human_name).tag(LLMModels.dbrx_together.human_name)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 180)

                LaunchAtLogin.Toggle("Launch at Login")
                    .toggleStyle(.switch)

                Toggle("Show on Menu Bar", isOn: $showMenuBar)
                    .toggleStyle(.switch)

                Toggle("Shortcut Hints", isOn: $shortcutHints)
                    .toggleStyle(.switch)

                Toggle("Beta Features", isOn: $betaFeatures)
                    .toggleStyle(.switch)
                    .onChange(of: betaFeatures) {
                        if betaFeatures {
                            logger.info("Beta features enabled")
                        } else {
                            logger.info("Beta features disabled")
                            // Reset beta features
                            animateButtons = true
                        }
                    }

                Divider()
                    .padding(.horizontal, 150)
                    .visible(if: betaFeatures, removeCompletely: true)

                Toggle("Animate Buttons", isOn: $animateButtons)
                    .toggleStyle(.switch)
                    .visible(if: betaFeatures, removeCompletely: true)

                Spacer()

                HStack {
                    Button("Reset Onboarding") {
                        onboardingViewed = false
                        OnboardingManager.shared.startOnboarding()
                    }
                    .buttonStyle(.bordered)

                    Button("Export Chat") {
                        let text = MessageViewModel.shared.messages.map { message in
                            "\(message.role?.rawValue.capitalized ?? ""): \(message.text)"
                        }.joined(separator: "\n")
                        document = TextDocument(text: text)
                        showingExporter = true
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    Button("Check for Updates") {
                        updaterViewModel.updater.checkForUpdates()
                    }
                    .buttonStyle(.bordered)

                    Button("Feedback") {
                        if let url = URL(string: "mailto:support@i.inc") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }

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
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
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
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://x.com/sulaimanghori") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    Text(" and ")
                        .font(.headline)
                    Text("Tye Daniel")
                        .font(.headline)
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://x.com/TyeDan") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                }

                Text("© 2024 Invisibility, Inc. All rights reserved. Version \(bundleVersion)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            .animation(.easeIn, value: betaFeatures)

            Spacer()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .frame(maxWidth: 600, maxHeight: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .shadow(radius: colorScheme == .dark ? 5 : 0)
        .focusable(false)
        .fileExporter(isPresented: $showingExporter, document: document, contentType: .plainText, defaultFilename: "invisibility.txt") { result in
            switch result {
            case let .success(url):
                logger.info("Saved to \(url)")
            case let .failure(error):
                logger.error(error.localizedDescription)
            }
        }
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
