//
//  EmailUtils.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/19/24.
//

import Foundation
import LLM
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "ai.grav.app", category: "EmailUtils")

func encodeForMailto(subject: String, body: String) -> String {
    let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    return "mailto:?subject=\(encodedSubject)&body=\(encodedBody)"
}

func generateFollowUp(_ input: String, message: Message) async {
    guard let llm = await LLMManager.shared.llm else {
        logger.error("LLM not available")
        return
    }

    guard let audio = message.audio else {
        logger.error("Audio not available")
        return
    }

    DispatchQueue.main.async { message.progress = 0.4 }
    let contentMessage = (role: ChatRole.user, content: input)
    logger.debug("Generating email on content: \(input)")

    let emailOutline = await llm.arespond(to: [contentMessage, (role: ChatRole.user, content: AppPrompts.emailPromptOutline)])
    let emailOutlineMessage = (role: ChatRole.user, content: emailOutline)
    DispatchQueue.main.async { message.progress = 0.8 }
    logger.debug("Email outline: \(emailOutline)")

    let emailFollowUp = await llm.arespond(to: [emailOutlineMessage, (role: ChatRole.user, content: AppPrompts.emailPromptFollowUp)])
    DispatchQueue.main.async { message.progress = 1.0 }
    logger.debug("Email follow-up: \(emailFollowUp)")

    let email = emailFollowUp
    audio.email = email
}
