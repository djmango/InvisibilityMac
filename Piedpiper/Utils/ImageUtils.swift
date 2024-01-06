//
//  Base64Image.swift
//  piedpiper
//
//  Created by Sulaiman Ghori on 1/4/24.
//

import Foundation
import AppKit
import CoreGraphics
import ImageIO
import CoreServices

extension CGImage {
    /// Converts a CGImage to a base64 string
    func toBase64String() -> String? {
        let nsImage = NSImage(cgImage: self, size: NSZeroSize)
        guard let tiffRepresentation = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
              let imageData = bitmapImage.representation(using: .png, properties: [:]) else { return nil }
        return imageData.base64EncodedString()
    }
}

extension String {
    /// Converts a base64 string to an NSImage
    func base64ToImage() -> NSImage? {
        guard let imageData = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return NSImage(data: imageData)
    }
}

/// Resizes a CG image to a pixel value, preserving aspect ratio
func resizeCGImage(_ cgImage: CGImage, toMaxSize maxSize: CGFloat) -> CGImage? {
    let width = CGFloat(cgImage.width)
    let height = CGFloat(cgImage.height)
    let aspectWidth = maxSize / width
    let aspectHeight = maxSize / height
    let aspectRatio = min(aspectWidth, aspectHeight)
    
    let newSize = CGSize(width: width * aspectRatio, height: height * aspectRatio)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    var bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    bitmapInfo |= CGBitmapInfo.byteOrder32Big.rawValue

    guard let context = CGContext(data: nil, width: Int(newSize.width), height: Int(newSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) else {
        return nil
    }

    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
    
    return context.makeImage()
}

func standardizeImage(_ image: CGImage, compressionQuality: CGFloat = 0.8) -> Data? {
    let mutableData = NSMutableData()
    let jpegUTI = "public.jpeg" as CFString
    
    guard let destination = CGImageDestinationCreateWithData(mutableData, jpegUTI, 1, nil) else {
        return nil
    }

    guard let resizedImage = resizeCGImage(image, toMaxSize: 1024) else {
        return nil
    }

    // Set the compression quality for the JPEG format
    let options = [kCGImageDestinationLossyCompressionQuality: compressionQuality] as CFDictionary

    // Add the image to the destination, specifying the compression quality
    CGImageDestinationAddImage(destination, image, options)

    // Finalize the destination to create the JPEG data
    guard CGImageDestinationFinalize(destination) else {
        return nil
    }

    return mutableData as Data
}
