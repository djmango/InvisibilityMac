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
        VStack(alignment: .center) {
            Spacer()
            Form {
                Section {
                    HStack {
                        Text("Summon Gravity:").bold()
                        KeyboardShortcuts.Recorder(for: .summon)
                    }
                }

                Section {
                    Toggle("Open Gravity at Login", isOn: $autoLaunch).bold()
                }

                Section {
                    Toggle("Sharing crash reports & analytics", isOn: $analytics).bold()
                }

                Section {
                    Toggle("Enable beta features", isOn: $newFeatures).bold()
                }
            }
            .frame(width: 500)
            .fixedSize()
            .padding()

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
