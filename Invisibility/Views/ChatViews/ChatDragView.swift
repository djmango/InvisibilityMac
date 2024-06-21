//
//  ChatDragView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/20/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct ChatDragResizeView: View {
    @Binding var isDragging: Bool
    @AppStorage("sideSwitched") private var sideSwitched: Bool = false

    @ObservedObject private var mainWindowViewModel: MainWindowViewModel = MainWindowViewModel.shared

    var isShowingHistory: Bool {
        mainWindowViewModel.whoIsVisible == .history
    }

    var body: some View {
        HStack {
            if !sideSwitched {
                Spacer()
            }

            Rectangle()
                // .fill(Color.white.opacity(0.1))
                .fill(Color.clear)
                .frame(width: 25)
                .onHover { hovering in
                    isDragging = hovering
                    // Set cursor to side to side drag resize icon
                    NSCursor.resizeLeftRight.set()
                }

            if sideSwitched {
                Spacer()
            }
        }
    }
}
