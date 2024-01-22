//
//  ImageViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/8/24.
//

import Foundation
import SwiftUI

/// ImageViewModel is an ObservableObject that stores the state of the expanded image view.
final class ImageViewModel: ObservableObject {
    @Published var image: NSImage? = nil
    // @Binding var isExpanded: Bool

    func setImage(image: NSImage) {
        self.image = image
    }

    func getImage() -> NSImage? {
        guard let image else {
            return nil
        }
        return image
    }

    func clearImage() {
        image = nil
    }
}
