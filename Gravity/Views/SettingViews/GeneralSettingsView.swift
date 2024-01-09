//
//  GeneralSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import KeyboardShortcuts
import SwiftUI

struct GeneralSettingsView: View {
    @State private var autoLaunch: Bool = true
    @State private var analytics: Bool = false
    @State private var newFeatures: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                HStack {
                    Text("Summon Gravity:").bold()
                    KeyboardShortcuts.Recorder(for: .summon)
                }
                .padding(.horizontal, 25)
                .padding(.top, 6)

                HStack {
                    Text("Auto-Launch:").bold()
                    Toggle("Open Gravity at Login", isOn: $autoLaunch)
                }
                .padding(.horizontal, 25)
                .padding(.top, 6)

                HStack {
                    Text("Analytics:").bold()
                    Toggle("Opt-in by sharing crash reports & usage data", isOn: $analytics)
                }
                .padding(.horizontal, 25)
                .padding(.top, 6)

                HStack {
                    Text("New Features:").bold()
                    Toggle("Enable early access to feature rollouts", isOn: $newFeatures)
                }
                .padding(.horizontal, 25)
                .padding(.top, 6)

                Spacer()
                HStack {
                    Spacer()
                    Button("Wipe All Data") {
                        print("Wiping all data...")
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
        // .focusEffectDisabled()
        .focusable(false)
        .frame(minWidth: 500, maxWidth: .infinity, minHeight: 150, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}
