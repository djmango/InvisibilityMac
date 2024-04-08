//
//  MessageImages.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/6/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct MessageImagesView: View {
    private let images: [Data]

    init(images: [Data]) {
        self.images = images
    }

    var body: some View {
        HStack {
            ForEach(images, id: \.self) { imageData in
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 5)
                        .shadow(radius: 2)
                }
            }
        }
    }
}
