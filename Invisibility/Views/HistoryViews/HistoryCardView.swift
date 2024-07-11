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
    @State private var isHovering: Bool = false

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
                    editabletitle
                    ProgressView()
                        .scaleEffect(0.4)
                        .visible(if: viewModel.isRenaming)
                    cancelButton
                    confirmButton
                    Spacer()
                    autoRenameButton
                    timeCreated
                }

                Spacer()
                subContent
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
            deleteCardButton
                .visible(if: isHovering)
        )
        .whenHovered { hovering in
            if hovering {
                withAnimation(.easeIn(duration: 0.2)) {
                    isHovering = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isHovering = false
                }
            }
        }
        .onTapGesture {
            viewModel.switchChat()
        }
    }
    
    // MARK: - Information
    var editabletitle: some View {
        TextField("Enter new name", text: $viewModel.editedName)
            .onSubmit {
                viewModel.commitEdit()
            }
            .font(.title3)
            .textFieldStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)
            .animation(.bouncy, value: viewModel.editedName)
    }
    
    var subContent: some View {
        Text(viewModel.lastMessageText)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)
    }
    
    var timeCreated: some View {
        Text(timeAgo(viewModel.lastMessageDate))
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    
    // MARK: - Buttons
    var confirmButton: some View {
        Button(action: viewModel.commitEdit) {
            Image(systemName: "checkmark")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.chatButtonForeground)
                .visible(if: viewModel.isEditing)
        }
        .buttonStyle(.plain)
    }
    
    var cancelButton: some View {
        Button(action: viewModel.cancelEdit) {
            Image(systemName: "xmark")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.chatButtonForeground)
                .visible(if: viewModel.isEditing)
        }
        .buttonStyle(.plain)
    }
    
    var autoRenameButton: some View {
        Button(action: viewModel.autoRename) {
            Image(systemName: "pencil.circle.fill")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.chatButtonForeground)
        }
        .buttonStyle(.plain)
    }
    
    var deleteCardButton: some View {
        VStack {
            HStack {
                Button(action: viewModel.deleteChat) {
                    Image(systemName: "xmark")
                        .resizable()
                        .padding(6)
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
    }
}

struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onEditingChanged: (Bool) -> Void
    var onCommit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context _: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func controlTextDidBeginEditing(_: Notification) {
            parent.onEditingChanged(true)
        }

        func controlTextDidEndEditing(_: Notification) {
            parent.onEditingChanged(false)
            parent.onCommit()
        }
    }
}
