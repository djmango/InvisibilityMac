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
    @ObservedObject var branchManagerModel = BranchManagerModel.shared

    private let isAssistant: Bool
    private let model_name: String
    private var isBranch: Bool

    init(message: APIMessage) {
        self.message = message
        self.isAssistant = message.role == .assistant
        self.model_name = LLMModelRepository.shared.model_id_2_name(message.model_id)
        self.isBranch = BranchManagerModel.shared.isBranch(message: message)
    }

    private var isEditing : Bool {
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
            
            if !isEditing {
                MarkdownWebView(message.text)
            } else {
                EditWebInputView()
            }
            
            HStack {
                Image(systemName: "arrow.left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture{
                        branchManagerModel.moveLeft(message: message)
                    }
                
                Image(systemName: "arrow.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture{
                        branchManagerModel.moveRight(message: message)
                    }
            }
            // is last msg && there exists chat wtih its id as parent_message_id
            .visible(if: isBranch, removeCompletely: true)
            
            HStack {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture {
                        // cleanup is handled in sendFromChat
                        Task{
                            await MessageViewModel.shared.sendFromChat(editMode: true)
                        }
                    }
                
                Image(systemName: "x.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture{
                        branchManagerModel.clearEdit()
                    }
            }
            .visible(if: isEditing, removeCompletely: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

