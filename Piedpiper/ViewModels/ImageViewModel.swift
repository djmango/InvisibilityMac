//
//  ImageViewModel.swift
//  piedpiper
//
//  Created by Sulaiman Ghori on 1/8/24.
//

import Foundation
import SwiftUI

/// ImageViewModel is an ObservableObject that stores the state of the expanded image view.
final class ImageViewModel: ObservableObject {
    @Published var image: NSImage? = nil
    @Published var originalFrame: CGRect? = nil
    // @Binding var isExpanded: Bool

    func setImage(image: NSImage, originalFrame: CGRect) {
        self.image = image
        self.originalFrame = originalFrame
    }

    func getImage() -> (NSImage, CGRect)? {
        guard let image, let originalFrame else {
            return nil
        }
        return (image, originalFrame)
    }

    func clearImage() {
        image = nil
        originalFrame = nil
    }
}
