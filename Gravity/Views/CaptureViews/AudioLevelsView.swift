/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A view that renders an audio level meter.
 */

import Foundation
import SwiftUI

struct AudioLevelsView: View {
    @ObservedObject var audioLevelsProvider: AudioLevelsProvider

    var body: some View {
        ZStack(alignment: .leading) {
            ProgressView(value: audioLevelsProvider.audioLevels.level)
                .foregroundColor(.green)
                .frame(width: 50, height: 5)
        }
        .cornerRadius(2.5)
    }
}
