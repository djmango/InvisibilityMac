//
//  MessageImagesView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/6/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct MessageImagesView: View {
    let images: [APIFile]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var ns_images: [NSImage] {
        images.compactMap { $0.url?.base64ToImage() }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(ns_images, id: \.self) { image in
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
            }
        }
        .padding(.vertical, 5)
    }
}
