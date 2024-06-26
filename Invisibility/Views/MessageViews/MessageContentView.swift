//
//  MessageContentView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/6/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import MarkdownWebView
import SwiftUI

struct MessageContentView: View {
    @ObservedObject var message: APIMessage
    @ObservedObject var hoverTrackerModel = HoverTrackerModel.shared
    @ObservedObject var branchManagerModel = BranchManagerModel.shared

    private let isAssistant: Bool
    private let model_name: String
    @State private var isHovering = false
    @State private var isEditingWithDelay = false

    init(message: APIMessage) {
        self.message = message
        self.isAssistant = message.role == .assistant
        self.model_name = LLMModelRepository.shared.model_id_2_name(message.model_id)
    }

    private var isEditing: Bool {
        guard let editMsg = branchManagerModel.editMsg else {
            return false
        }
        return editMsg.id == message.id
    }

    private var isGenerating: Bool {
        MessageViewModel.shared.isGenerating && message.text.isEmpty
    }

    private var isLastMessage: Bool {
        message.id == MessageViewModel.shared.api_messages.last?.id
    }

    private var showLoading: Bool {
        isGenerating && isLastMessage
    }

    private var images: [APIFile] {
        MessageViewModel.shared.shownImagesFor(message: message)
    }
    
    private var showEditButtons:Bool {
//        print("showEditButton:")
 //       print(hoverTrackerModel.targetItem)
        let ret = !isEditing && (hoverTrackerModel.targetItem == message.id.uuidString) && !isAssistant
        return ret
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isAssistant ? model_name : "You")
                .font(.custom("SF Pro Display", size: 13))
                .fontWeight(.bold)
                .tracking(-0.01)
                .lineSpacing(10)
                .opacity(0)
                .overlay(LinearGradient(
                    gradient: isAssistant ?
                        Gradient(colors: [.invisGrad1, .invisGrad2]) :
                        Gradient(colors: [.youText, .youText]),
                    startPoint: .leading, endPoint: .trailing
                ))
                .mask(
                    Text(isAssistant ? model_name : "You")
                        .font(.custom("SF Pro Display", size: 13))
                        .fontWeight(.bold)
                        .tracking(-0.01)
                        .lineSpacing(10)
                )
            ProgressView()
                .controlSize(.small)
                .visible(if: isGenerating && isLastMessage, removeCompletely: true)
            HStack {
                MessageImagesView(images: images)
                    .visible(if: !images.isEmpty, removeCompletely: true)
            }
            .visible(if: !images.isEmpty, removeCompletely: true)
            MarkdownWebView(message.text)
                .visible(if: !isEditing, removeCompletely: true)
            /*
            EditWebInputView()
                .visible(if: isEditing, removeCompletely: true)
             */
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
