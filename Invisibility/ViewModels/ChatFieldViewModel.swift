//
//  ChatFieldViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

final class ChatFieldViewModel: ObservableObject {
    static let shared = ChatFieldViewModel()

    /// A boolean value that indicates whether the text field should be focused.
    @Published public var shouldFocusTextField: Bool = false

    /// List of JPEG images and items to be sent with the message
    @Published public var items: [ChatDataItem] = []

    /// A string representing the file content of PDFs and text files added to the chat.
    public var fileContent: String = ""

    public var images: [ChatDataItem] {
        items.filter { $0.dataType == .jpeg }
    }

    public var pdfs: [ChatDataItem] {
        items.filter { $0.dataType == .pdf }
    }

    private init() {}

    @MainActor
    public func focusTextField() {
        shouldFocusTextField = true
    }
    
    // NOTE: animation causes flickering glitch, off for now
    @MainActor
    public func addImage(_ data: Data, hide: Bool = false) {
        //withAnimation(AppConfig.snappy) {
            items.append(ChatDataItem(data: data, dataType: .jpeg, hide: hide))
        //}
    }

    @MainActor
    public func removeItem(id: UUID) {
        //withAnimation(AppConfig.snappy) {
            items.removeAll { $0.id == id }
        //}
    }

    @MainActor
    public func removeAll() {
//        withAnimation(AppConfig.snappy) {
            items.removeAll()
            fileContent = ""
 //       }
    }
}
