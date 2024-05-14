/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 The app's main view.
 */

import Combine
import OSLog
import ScreenCaptureKit
import SwiftUI

struct CaptureView: View {
    @ObservedObject var screenRecorder = ScreenRecorder.shared
    // State object might be better here
    @State private var whoIsHovering: String?
    @State private var isHovering: Bool = false
    @State private var minimized: Bool = false

    var body: some View {
        screenRecorder.capturePreview
            .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("ChatButtonBackgroundColor"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .overlay(
                MessageButtonItemView(
                    label: "Open Picker",
                    icon: "rectangle.inset.filled.and.person.filled",
                    shortcut_hint: nil,
                    whoIsHovering: $whoIsHovering
                ) {
                    screenRecorder.presentPicker()
                }
                .visible(if: isHovering, removeCompletely: true)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
            )
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        MessageButtonItemView(
                            label: "Minimize",
                            icon: "minus",
                            shortcut_hint: nil,
                            whoIsHovering: $whoIsHovering
                        ) {
                            minimized.toggle()
                        }
                        .visible(if: isHovering, removeCompletely: true)
                        .animation(.easeInOut(duration: 0.2), value: isHovering)
                        .offset(x: 15, y: -15)
                        Spacer()
                    }
                }
            )
            .padding(10)
            .frame(maxWidth: 350)
            .onHover { hovering in
                isHovering = hovering
            }
            .onAppear {
                Task {
                    if await !screenRecorder.canRecord {
                        screenRecorder.isUnauthorized = true
                    }
                }
            }
            .visible(if: !minimized, removeCompletely: true)
            .animation(.easeInOut(duration: 0.2), value: minimized)
    }
}
