//
//  QRView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/15/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRView: View {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    private let string: String

    init(string: String) {
        self.string = string
    }

    var body: some View {
        Image(nsImage: generateQRCode(from: string))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }

    private func generateQRCode(from string: String) -> NSImage {
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: 100, height: 100))
            }
        }
        return NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil) ?? NSImage()
    }
}
