//
//  ChatImageView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import OSLog
import SwiftUI

struct ChatImageView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatImage")

    let imageItem: ChatDataItem
    let nsImage: NSImage
    @Binding private var whichImageIsHovering: UUID?

    var isHovering: Bool {
        whichImageIsHovering == imageItem.id
    }

    init(imageItem: ChatDataItem, whichImageIsHovering: Binding<UUID?>) {
        self.imageItem = imageItem
        self.nsImage = NSImage(data: imageItem.data) ?? NSImage()
        self._whichImageIsHovering = whichImageIsHovering
    }

    var body: some View {
        Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: isHovering ? 4 : 0)
            .padding(.horizontal, 10)
            .onHover { hovering in
                if hovering {
                    whichImageIsHovering = imageItem.id
                } else {
                    // First check if we still have command over var, ensuring someone else hasn't changed it
                    if whichImageIsHovering == imageItem.id {
                        whichImageIsHovering = nil
                    }
                }
            }
            .onTapGesture {
                ChatViewModel.shared.removeItem(id: imageItem.id)
            }
            .animation(.easeIn(duration: 0.2), value: ChatViewModel.shared.images)
    }
}
