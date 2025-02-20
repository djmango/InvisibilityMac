//
//  ImageUtils.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/4/24.
//

import AppKit
import CoreGraphics
import CoreServices
import Foundation
import ImageIO

// Image cache using NSCache
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, NSImage>()
    private let processingQueue = DispatchQueue(label: "com.invisibility.imageProcessing", qos: .userInitiated)
    
    private init() {
        cache.countLimit = 100 // Adjust based on memory requirements
    }
    
    func image(forKey key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: NSImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func processImage(_ image: CGImage, operation: @escaping (CGImage) -> NSImage?, completion: @escaping (NSImage?) -> Void) {
        processingQueue.async {
            let result = operation(image)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

extension CGImage {
    /// Converts a CGImage to a base64 string with caching
    func toBase64String() -> String? {
        let cacheKey = "base64_\(width)_\(height)"
        
        if let cachedImage = ImageCache.shared.image(forKey: cacheKey) {
            guard let tiffRepresentation = cachedImage.tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
                  let imageData = bitmapImage.representation(using: .png, properties: [:])
            else { return nil }
            return imageData.base64EncodedString()
        }
        
        let nsImage = NSImage(cgImage: self, size: NSZeroSize)
        ImageCache.shared.setImage(nsImage, forKey: cacheKey)
        
        guard let tiffRepresentation = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
              let imageData = bitmapImage.representation(using: .png, properties: [:])
        else { return nil }
        return imageData.base64EncodedString()
    }
}

extension String {
    /// Converts a base64 string to an NSImage with caching
    func base64ToImage() -> NSImage? {
        let cacheKey = "image_\(self.hash)"
        
        if let cachedImage = ImageCache.shared.image(forKey: cacheKey) {
            return cachedImage
        }
        
        var base64String = self
        if let range = base64String.range(of: "base64,") {
            base64String = String(base64String[range.upperBound...])
        }
        
        guard let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters),
              let image = NSImage(data: imageData) else {
            return nil
        }
        
        ImageCache.shared.setImage(image, forKey: cacheKey)
        return image
    }
}

/// Resizes a CG image to a pixel value, preserving aspect ratio with background processing
func resizeCGImage(_ cgImage: CGImage, toMaxSize maxSize: CGFloat, completion: @escaping (CGImage?) -> Void) {
    let cacheKey = "resize_\(cgImage.width)_\(cgImage.height)_\(maxSize)"
    
    if let cachedImage = ImageCache.shared.image(forKey: cacheKey)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        completion(cachedImage)
        return
    }
    
    ImageCache.shared.processImage(cgImage) { image -> NSImage? in
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let aspectWidth = maxSize / width
        let aspectHeight = maxSize / height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let newSize = CGSize(width: width * aspectRatio, height: height * aspectRatio)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        bitmapInfo |= CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(
            data: nil, width: Int(newSize.width), height: Int(newSize.height),
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            completion(nil)
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: newSize))
        
        guard let resizedImage = context.makeImage() else {
            completion(nil)
            return nil
        }
        
        let nsImage = NSImage(cgImage: resizedImage, size: newSize)
        ImageCache.shared.setImage(nsImage, forKey: cacheKey)
        completion(resizedImage)
        return nsImage
    } completion: { _ in }
}

/// Standardizes an image to a JPEG with max size and compression quality, and returns as Data
func standardizeImage(_ image: CGImage, compressionQuality: CGFloat = 0.8, maxSize: CGFloat = 1028) -> Data? {
    var resultData: Data?
    let semaphore = DispatchSemaphore(value: 0)
    
    let cacheKey = "standard_\(image.width)_\(image.height)_\(compressionQuality)_\(maxSize)"
    
    ImageCache.shared.processImage(image) { cgImage -> NSImage? in
        let mutableData = NSMutableData()
        let jpegUTI = "public.jpeg" as CFString
        
        guard let destination = CGImageDestinationCreateWithData(mutableData, jpegUTI, 1, nil) else {
            semaphore.signal()
            return nil
        }
        
        resizeCGImage(cgImage, toMaxSize: maxSize) { resizedImage in
            guard let resizedImage = resizedImage else {
                semaphore.signal()
                return
            }
            
            let options = [kCGImageDestinationLossyCompressionQuality: compressionQuality] as CFDictionary
            CGImageDestinationAddImage(destination, resizedImage, options)
            
            if CGImageDestinationFinalize(destination) {
                resultData = mutableData as Data
            }
            semaphore.signal()
        }
        return nil
    } completion: { _ in }
    
    _ = semaphore.wait(timeout: .now() + 5.0)  // Add timeout to prevent infinite wait
    return resultData
}
