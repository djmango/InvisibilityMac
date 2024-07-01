//
//  HistoryCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct HistoryCardView: View {
    @StateObject private var viewModel: HistoryCardViewModel
    @FocusState private var isFocused: Bool
    @State private var isHovering: Bool = false
    @State var isNameHovered: Bool = false

    init(chat: APIChat) {
        _viewModel = StateObject(wrappedValue: HistoryCardViewModel(chat: chat))
    }

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(.history)
                .frame(width: 5)
                .padding(.trailing, 5)

            VStack(alignment: .leading) {
                HStack {
                    if viewModel.isEditing {
                        TextField("Enter new name", text: $viewModel.editedName, onCommit: viewModel.commitEdit)
                            .font(.title3)
                            .textFieldStyle(.plain)
                            .focused($isFocused)
                            .onAppear { isFocused = true }
                    } else {
                        HStack {
                            Text(viewModel.chat.name)
                                .font(.title3)

                            Image(systemName: "pencil")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.chatButtonForeground)
                                .visible(if: isNameHovered)
                        }
                        .onHover { isNameHovered = $0 }
                        .onTapGesture(perform: viewModel.startEditing)
                    }

                    Spacer()

                    Text(viewModel.formattedDate(viewModel.lastMessageDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(viewModel.lastMessageText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.bottom, 5)
            }
        }
        .frame(height: 60)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
                .shadow(radius: 2)
        )
        .overlay(
            VStack {
                HStack {
                    Button(action: viewModel.deleteChat) {
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
            .visible(if: isHovering)
        )
        .whenHovered { hovering in
            withAnimation(AppConfig.snappy) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            viewModel.switchChat()
        }
    }
}
