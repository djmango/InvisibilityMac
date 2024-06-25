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
    @State private var isHovering = false
    @State private var leftArrowHovered = false
    @State private var rightArrowHovered = false
    @State private var isEditingWithDelay = false

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
    
    private var canMoveLeft: Bool {
        BranchManagerModel.shared.canMoveLeft(message: message)
    }
    
    private var canMoveRight: Bool {
        BranchManagerModel.shared.canMoveRight(message: message)
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
            
            ZStack {
               MarkdownWebView(message.text)
                   .opacity(isEditingWithDelay ? 0 : 1)
                   .animation(.easeInOut(duration: 0.2), value: isEditingWithDelay)
                if isEditing {
                   EditWebInputView()
                       .opacity(isEditingWithDelay ? 1 : 0)
                }
           }
           .onChange(of: isEditing) { newValue in
               if newValue {
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                       isEditingWithDelay = true
                   }
               } else {
                   isEditingWithDelay = false
               }
           }
           
            HStack {
                Image(systemName: leftArrowHovered && canMoveLeft ? "arrowtriangle.backward.fill" : "arrowtriangle.backward")
                   .resizable()
                   .aspectRatio(contentMode: .fit)
                   .frame(width: 15, height: 15)
                   .foregroundColor(.chatButtonForeground)
                   .onTapGesture {
                       branchManagerModel.moveLeft(message: message)
                   }
                   .onHover{ hovered in
                       if hovered {
                           leftArrowHovered = true
                           NSCursor.pointingHand.set()
                       } else {
                           leftArrowHovered = false
                           NSCursor.arrow.set()
                       }
                   }
                

                Image(systemName: rightArrowHovered && canMoveRight ? "arrowtriangle.forward.fill" : "arrowtriangle.forward")
                   .resizable()
                   .aspectRatio(contentMode: .fit)
                   .frame(width: 15, height: 15)
                   .foregroundColor(.chatButtonForeground)
                   .onTapGesture {
                       branchManagerModel.moveRight(message: message)
                   }
                   .onHover { hovered in
                       if hovered {
                           rightArrowHovered = true
                           NSCursor.pointingHand.set()
                       } else {
                           rightArrowHovered = false
                           NSCursor.arrow.set()
                       }
                   }
            }
            // is last msg && there exists chat wtih its id as parent_message_id
            .opacity(isHovering ? 1 : 0)
            .animation(AppConfig.snappy, value: isHovering)
            .visible(if: !isEditing && isBranch, removeCompletely: true)
            
            HStack {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture {
                        // cleanup is handled in sendFromChat
                        Task{
                            await MessageViewModel.shared.sendFromChat(editMode: true)
                        }
                    }
                    .onHover{ hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }

                Image(systemName: "x.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .foregroundColor(.chatButtonForeground)
                    .onTapGesture{
                        branchManagerModel.clearEdit()
                    }
                    .onHover{ hovered in
                        if hovered {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
            }
            .visible(if: isEditing, removeCompletely: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .onHover { hovering in
                   isHovering = hovering
        }
    }
}

