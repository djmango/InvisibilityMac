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

    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    var xOffset: CGFloat {
        sideSwitched ? -15 : 15
    }

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
                VStack {
                    HStack {
                        Spacer()
                            .visible(if: !sideSwitched, removeCompletely: true)
                        MessageButtonItemView(
                            label: "Minimize",
                            icon: "minus",
                            shortcut_hint: nil,
                            whoIsHovering: $whoIsHovering
                        ) {
                            withAnimation(AppConfig.snappy) {
                                minimized.toggle()
                            }
                        }
                        .offset(x: xOffset, y: -15)

                        Spacer()
                            .visible(if: sideSwitched, removeCompletely: true)
                    }

                    HStack {
                        Spacer()
                            .visible(if: !sideSwitched, removeCompletely: true)

                        MessageButtonItemView(
                            label: "Open Picker",
                            icon: "rectangle.inset.filled.and.person.filled",
                            shortcut_hint: nil,
                            whoIsHovering: $whoIsHovering
                        ) {
                            screenRecorder.presentPicker()
                        }
                        .offset(x: xOffset, y: -15)

                        Spacer()
                            .visible(if: sideSwitched, removeCompletely: true)
                    }

                    Spacer()
                }
                .visible(if: isHovering, removeCompletely: true)
            )
            // .padding(10)
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
            .animation(.easeInOut(duration: 0.2), value: whoIsHovering)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 3)
    }
}
