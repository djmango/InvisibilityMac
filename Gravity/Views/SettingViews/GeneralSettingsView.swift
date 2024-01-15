//
//  GeneralSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("autoLaunch") private var autoLaunch: Bool = false
    @AppStorage("analytics") private var analytics: Bool = true
    @AppStorage("betaFeatures") private var betaFeatures: Bool = false
    @AppStorage("emailAddress") private var emailAddress: String = ""

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Form {
                Section {
                    HStack {
                        Text("Summon Gravity:").bold()
                        KeyboardShortcuts.Recorder(for: .summon)
                    }
                }

                LaunchAtLogin.Toggle().bold()

                Section {
                    Toggle("Share crash reports & analytics", isOn: $analytics).bold()
                }

                Section {
                    Toggle("Enable beta features", isOn: $betaFeatures).bold()
                }

                Section {
                    TextField("Email Address", text: $emailAddress)
                        .bold()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 350)
                }
            }
            .frame(width: 500)
            .fixedSize()

            Spacer()
            HStack {
                Spacer()
                Button("Wipe All Data") {
                    print("Wiping all data...")
                }
                .foregroundColor(.red)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .focusable(false)
    }
}
