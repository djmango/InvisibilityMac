//
//  ExpandedImageView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/8/24.
//

import AppKit
import SwiftUI

struct ExpandedImageView: View {
    let nsImage: NSImage
    let originalFrame: CGRect
    let geometry: GeometryProxy
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 0.0

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }

            // Image view
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .padding()
                .frame(width: originalFrame.size.width, height: originalFrame.size.height)
                .scaleEffect(scale)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scale = 1.0 // Animate to full size
                    }
                }

            // Close button
            // VStack {
            //     HStack {
            //         Spacer()
            //         Button(action: { withAnimation {
            //             onDismiss()
            //         }
            //         }) {
            //             Image(systemName: "xmark.circle.fill")
            //                 .font(.title)
            //                 .padding()
            //         }
            //     }
            //     Spacer()
            // }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// #Preview {
//     ExpandedImageView()
// }
