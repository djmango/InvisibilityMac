//
//  HistoryCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import MarkdownWebView
import SwiftUI

struct HistoryCardView: View {
    let chat: APIChat

    @ObservedObject private var messageViewModel: MessageViewModel = MessageViewModel.shared
    private var chatViewModel: ChatViewModel = ChatViewModel.shared
    private var mainWindowViewModel: MainWindowViewModel = MainWindowViewModel.shared

    @State private var editedName: String = ""
    @State private var isHovered: Bool = false
    @State private var isNameHovered: Bool = false
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool

    // var shouldHighlight: Bool {
    //     chatViewModel.chat == chat || isHovered
    // }

    init(chat: APIChat) {
        self.chat = chat
    }

    func formattedDate(_ date: Date) -> String {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateStyle = .long
        dateTimeFormatter.timeStyle = .short
        return dateTimeFormatter.string(from: date)
    }

    var body: some View {
        // let _ = Self._printChanges()
        HStack {
            // TODO: Capture the esc action so that people can exit the editing mode
            RoundedRectangle(cornerRadius: 5)
                .fill(.history)
                .frame(width: 5)
                .padding(.trailing, 5)

            VStack(alignment: .leading) {
                HStack {
                    if isEditing {
                        TextField("Enter new name", text: $editedName, onCommit: {
                            // If the name is not empty, rename the chat
                            if !editedName.isEmpty {
                                chatViewModel.renameChat(chat, name: editedName)
                            } else {
                                editedName = chat.name
                            }
                            isEditing = false
                        })
                        .font(.title3)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onAppear {
                            isFocused = true
                        }
                    } else {
                        HStack {
                            Text(chat.name)
                                .font(.title3)

                            Image(systemName: "pencil")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.chatButtonForeground)
                                .visible(if: isNameHovered)
                        }
                        .onHover {
                            if $0 {
                                withAnimation(AppConfig.easeOut) {
                                    isNameHovered = true
                                }
                            } else {
                                withAnimation(AppConfig.easeOut) {
                                    isNameHovered = false
                                }
                            }
                        }
                        .onTapGesture {
                            // If not New Chat, give the current name as the starting point
                            if chat.name != "New Chat" {
                                editedName = chat.name
                            }
                            isEditing = true
                        }
                    }

                    Spacer()

                    Text(formattedDate(messageViewModel.lastMessageWithTextFor(chat: chat)?.created_at ?? chat.created_at))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(messageViewModel.lastMessageWithTextFor(chat: chat)?.text ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.bottom, 5)
            }
        }
        .frame(height: 60)
        .padding()
        // NOTE: the order of these 3 elements, stroke -> background -> overlay is important, it creates the nicest effect
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            // .stroke(Color(NSColor.separatorColor), lineWidth: chatViewModel.chat == chat ? 3 : 1)
            // .stroke(chatViewModel.chat == chat ? .history : Color(NSColor.separatorColor), lineWidth: chatViewModel.chat == chat ? 2 : 1)
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                .shadow(radius: 2)
        )
        .overlay(
            // The X delete button
            VStack {
                HStack {
                    Button(action: {
                        chatViewModel.deleteChat(chat)
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .padding(5)
                            .foregroundColor(.chatButtonForeground)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                            .background(
                                Circle()
                                    .fill(Color.cardBackground)
                                    .shadow(radius: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(width: 21, height: 21)
                    .padding(.leading, -5)
                    .padding(.top, -5)

                    Spacer()
                }
                Spacer()
            }
            .visible(if: isHovered)
        )
        .onHover {
            if $0 {
                isHovered = true
                // Preemtively load the chat, snappier!
                // Wait until the hover animation is done to show the history
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Check if still hovered
                    if isHovered {
                        chatViewModel.switchChat(chat)
                    }
                }
            } else {
                withAnimation(AppConfig.easeOut) {
                    isHovered = false
                }
            }
        }
        .onTapGesture {
            chatViewModel.switchChat(chat)
            _ = mainWindowViewModel.changeView(to: .chat)
        }
    }
}
