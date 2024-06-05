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
    @Binding private var whoIsHovering: UUID?

    var isHovering: Bool {
        whoIsHovering == imageItem.id
    }

    init(imageItem: ChatDataItem, whoIsHovering: Binding<UUID?>) {
        self.imageItem = imageItem
        self.nsImage = NSImage(data: imageItem.data) ?? NSImage()
        self._whoIsHovering = whoIsHovering
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
                    whoIsHovering = imageItem.id
                } else {
                    // First check if we still have command over var, ensuring someone else hasn't changed it
                    if whoIsHovering == imageItem.id {
                        whoIsHovering = nil
                    }
                }
            }
            .onTapGesture {
                ChatViewModel.shared.removeItem(id: imageItem.id)
            }
            .animation(AppConfig.easeIn, value: ChatViewModel.shared.images)
    }
}
