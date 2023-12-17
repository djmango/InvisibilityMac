//
//  FilePicker.swift
//  piedpiper
//
//  Created by Sulaiman Ghori on 12/17/23.
//

import Foundation
import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class FilePicker {
    static func openFile(completion: @escaping (URL?) -> Void) {
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
            UTType.heif,
            UTType.image
        ]

        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                completion(url)
            } else {
                completion(nil)
            }
        }
    }
}
