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

    var body: some View {
        screenRecorder.capturePreview
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .padding(10)
            .frame(maxWidth: 350)
            .onAppear {
                Task {
                    if await !screenRecorder.canRecord {
                        screenRecorder.isUnauthorized = true
                    }
                }
            }
    }
}
