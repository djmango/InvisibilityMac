//
//  OpenFileChatView.swift
//  piedpiper
//
//  Created by Sulaiman Ghori on 12/18/23.
//

import Foundation
import Cocoa
import SwiftUI
import UniformTypeIdentifiers
import CoreGraphics
import Vision

class FileOpener: ObservableObject {
    func openFile(completionHandler: @escaping VNRequestCompletionHandler) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        
        // Define allowed content types using UTType
        openPanel.allowedContentTypes = [
            UTType.png,
            UTType.jpeg,
            UTType.gif,
            UTType.bmp,
            UTType.tiff,
            UTType.heif
        ]
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                    return
                }

                guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                    return
                }
                
                // Create a new image-request handler.
                let requestHandler = VNImageRequestHandler(cgImage: cgImage)

                // Create a new request to recognize text.
                let request = VNRecognizeTextRequest(completionHandler: completionHandler)
        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
            } else {
                print("ERROR: Couldn't grab file url for some reason")
            }
        }
    }
    
}
