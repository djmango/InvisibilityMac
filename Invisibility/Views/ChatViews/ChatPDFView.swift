//
//  ChatPDFView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/16/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct ChatPDFView: View {
    let item: ChatDataItem

    @Binding private var whoIsHovering: UUID?

    var isHovering: Bool {
        whoIsHovering == item.id
    }

    init(pdfItem: ChatDataItem, whoIsHovering: Binding<UUID?>) {
        self.item = pdfItem
        self._whoIsHovering = whoIsHovering
    }

    var body: some View {
        Image("PDFIcon")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 150, height: 150)
            .shadow(radius: isHovering ? 4 : 0)
            .padding(.horizontal, 10)
            .onHover { hovering in
                if hovering {
                    whoIsHovering = item.id
                } else {
                    // First check if we still have command over var, ensuring someone else hasn't changed it
                    if whoIsHovering == item.id {
                        whoIsHovering = nil
                    }
                }
            }
            .onTapGesture {
                ChatViewModel.shared.removeItem(id: item.id)
            }
            .animation(.easeIn(duration: 0.2), value: ChatViewModel.shared.items)
    }
}
