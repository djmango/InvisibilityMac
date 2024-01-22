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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(scale)
                .position(x: 0, y: 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scale = 1.0 // Animate to full size
                    }
                }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
