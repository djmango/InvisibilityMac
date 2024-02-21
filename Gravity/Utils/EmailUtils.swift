//
//  EmailUtils.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/19/24.
//

import Foundation
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "ai.grav.app", category: "EmailUtils")

func encodeForMailto(subject: String, body: String) -> String {
    let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    return "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
}

func generateFollowUp(_ input: String, message: Message) async {
    guard let audio = message.audio else {
        logger.error("Audio not available")
        return
    }

    DispatchQueue.main.async { message.progress = 0.4 }
    let contentMessage = Message(content: input, role: .user)
    logger.debug("Generating email on content: \(input)")

    let emailOutline = await LLMManager.shared.achat(messages: [contentMessage, Message(content: AppPrompts.emailPromptOutline, role: .user)])
    let emailOutlineMessage = Message(content: emailOutline.content, role: .user)
    DispatchQueue.main.async { message.progress = 0.8 }
    logger.debug("Email outline: \(emailOutline)")

    let emailFollowUp = await LLMManager.shared.achat(messages: [emailOutlineMessage, Message(content: AppPrompts.emailPromptFollowUp, role: .user)])
    DispatchQueue.main.async { message.progress = 1.0 }
    logger.debug("Email follow-up: \(emailFollowUp)")

    audio.email = emailFollowUp.content
}
