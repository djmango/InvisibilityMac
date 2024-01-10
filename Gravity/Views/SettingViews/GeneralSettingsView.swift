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

                LaunchAtLogin.Toggle()

                Section {
                    Toggle("Share crash reports & analytics", isOn: $analytics).bold()
                }

                Section {
                    Toggle("Enable beta features", isOn: $betaFeatures).bold()
                }
            }
            .frame(width: 500)
            .fixedSize()
            // .padding()

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
