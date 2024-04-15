//
//  ChatViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/29/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog

enum DataType: String {
    case pdf
    case image
}

struct ChatDataItem: Identifiable, Equatable {
    let id = UUID()
    let data: Data
    let dataType: DataType

    init(data: Data, dataType: DataType) {
        self.data = data
        self.dataType = dataType
    }

    static func == (lhs: ChatDataItem, rhs: ChatDataItem) -> Bool {
        lhs.id == rhs.id
    }
}

final class ChatViewModel: ObservableObject {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "ChatViewModel")

    static let shared = ChatViewModel()

    /// A boolean value that indicates whether the text field should be focused.
    @Published public var shouldFocusTextField: Bool = false

    /// List of JPEG images and files to be sent with the message
    @Published public var files: [ChatDataItem] = []

    public var images: [ChatDataItem] {
        files.filter { $0.dataType == .image }
    }

    /// The height of the text field.
    @Published public var textHeight: CGFloat = 52

    private init() {}

    @MainActor
    public func addImage(_ data: Data) {
        files.append(ChatDataItem(data: data, dataType: .image))
    }

    public func addPDF(_ data: Data) {
        files.append(ChatDataItem(data: data, dataType: .pdf))
    }

    @MainActor
    public func removeItem(id: UUID) {
        files.removeAll { $0.id == id }
    }

    @MainActor
    public func removeAll() {
        files.removeAll()
    }

    @MainActor
    public func focusTextField() {
        shouldFocusTextField = true
    }
}
