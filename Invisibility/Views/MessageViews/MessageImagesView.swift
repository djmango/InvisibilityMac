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
    let spacing: CGFloat = 10
    let itemWidth: CGFloat = 150
    
    @AppStorage("width") private var windowWidth: Int = WindowManager.defaultWidth

    private var columns: [GridItem] {
        let availableWidth = CGFloat(windowWidth)
        let numColumns = min(images.count, Int((availableWidth / (itemWidth + spacing)).rounded(.down)))
        return Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: numColumns)
    }

    var ns_images: [NSImage] {
        images.compactMap { $0.url?.base64ToImage() }
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
            ForEach(ns_images, id: \.self) { image in
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: itemWidth, height: itemWidth)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
            }
        }
        .padding(.vertical, spacing)
        .padding(.horizontal, spacing)
    }
}
