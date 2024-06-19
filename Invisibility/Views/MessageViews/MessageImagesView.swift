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
           GridItem(.flexible())
    ]

    var ns_images: [NSImage] {
        images.compactMap { $0.url?.base64ToImage() }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20){
            ForEach(ns_images, id: \.self) { image in
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 2)
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, 10)
    }
}
