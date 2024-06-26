//
//  InvisibilityFileManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog
import PDFKit
import PostHog
import SwiftUI
import UniformTypeIdentifiers

enum InvisibilityFileManager {
    static var logger = Logger(subsystem: AppConfig.subsystem, category: "FileManager")

    /// Public function that can be called to begin the file open process
    public static func openFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        // Define allowed content types using UTType
        openPanel.allowedContentTypes = [
            UTType.image,
            UTType.pdf,
            UTType.text,
        ]

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                self.handleFile(url)
            }
        }

        PostHogSDK.shared.capture("open_file")
    }

    public static func handleDrop(providers: [NSItemProvider]) -> Bool {
        // logger.debug("Providers: \(providers)")
        for provider in providers {
            // logger.debug("Provider: \(provider.description)")
            // logger.debug("Provider types: \(provider.registeredTypeIdentifiers)")
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    guard error == nil else {
                        self.logger.error("Error loading the dropped item: \(error!)")
                        return
                    }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        // Process the file URL
                        // self.logger.debug("File URL: \(url)")
                        self.handleFile(url)
                    }
                }
            } else {
                logger.error("Unsupported item provider type")
            }
        }
        return true
    }

    /// Public function that handles file via a URL regarding a message
    public static func handleFile(_ url: URL) {
        defer {
            PostHogSDK.shared.capture("handle_file")
        }

        // First determine if we are dealing with an image or audio file
        logger.debug("Selected file \(url)")
        if let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            // Check if it's an image type
            if fileType.conforms(to: .image) {
                logger.debug("Selected file \(url) is an image.")
                handleImage(url: url)
            } else if fileType.conforms(to: .pdf) {
                logger.debug("Selected file \(url) is a PDF.")
                handlePDF(url: url)
            } else if fileType.conforms(to: .text) {
                logger.debug("Selected file \(url) is a text file.")
                handleText(url: url)
            } else {
                logger.error("Selected file \(url) is of an unknown type.")
                ToastViewModel.shared.showToast(
                    title: "Unsupported file type"
                )
            }
        }
    }

    private static func handleImage(url: URL) {
        defer { PostHogSDK.shared.capture("handle_image") }
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            logger.error("Failed to create image source from url.")
            return
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            logger.error("Failed to create image from image source.")
            return
        }

        // Standardize and convert the image to a base64 string and store it in the view model
        guard let standardizedImage = standardizeImage(cgImage) else {
            logger.error("Failed to standardize image.")
            return
        }

        DispatchQueue.main.async {
            ChatFieldViewModel.shared.addImage(standardizedImage)
        }
    }

    private static func handlePDF(url: URL) {
        defer { PostHogSDK.shared.capture("handle_pdf") }
        guard let pdf = PDFDocument(url: url) else {
            logger.error("Failed to read PDF data from url.")
            return
        }

        guard let _ = pdf.dataRepresentation() else {
            logger.error("Failed to get data representation from PDF.")
            return
        }

        var complete_text = ""

        // Insert PDF attributedString if available
        if let pdf = PDFDocument(url: url) {
            let pageCount = pdf.pageCount
            let documentContent = NSMutableAttributedString()

            for i in 0 ..< pageCount {
                guard let page = pdf.page(at: i) else { continue }
                guard let pageContent = page.attributedString else { continue }
                documentContent.append(pageContent)
            }

            complete_text += documentContent.string
        }

        DispatchQueue.main.async {
            ChatFieldViewModel.shared.fileContent += complete_text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func handleText(url: URL) {
        defer { PostHogSDK.shared.capture("handle_text") }
        guard let data = try? Data(contentsOf: url) else {
            logger.error("Failed to read text data from url.")
            return
        }

        guard let text = String(data: data, encoding: .utf8) else {
            logger.error("Failed to convert text data to string.")
            return
        }

        DispatchQueue.main.async {
            ChatFieldViewModel.shared.fileContent += text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
