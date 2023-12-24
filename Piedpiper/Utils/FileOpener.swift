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
    let messageViewModel: MessageViewModel
    
    init(messageViewModel: MessageViewModel) {
        self.messageViewModel = messageViewModel
    }
    
    func openFile() {
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
                self.handleFile(url: url)
            } else {
                print("ERROR: Couldn't grab file url for some reason")
            }
        }
    }
    
    private func handleFile(url: URL) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return
        }

        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return
        }
        
        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)


        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        // Append the recognized strings to chat. Should design this better, just appending is dumb.
        let joined = recognizedStrings.joined(separator: " ")
//        messageViewModel.messages.append(Message(content: "Take a a look at this image for me", role: Role.user))
//        messageViewModel.messages.append(Message(content: "It says: \(joined)", role: Role.assistant))
    }
}
