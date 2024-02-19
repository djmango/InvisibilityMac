//
//  AppPrompts.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import Foundation

enum AppPrompts {
    static let summarizeChunk = "Can you provide a comprehensive summary of the given text? The summary should cover all the key points and main ideas presented in the original text, while also condensing the information into a concise and easy-to-understand format. Please ensure that the summary includes relevant details and examples that support the main ideas, while avoiding any unnecessary information or repetition. The length of the summary should be appropriate for the length and complexity of the original text, providing a clear and accurate overview without omitting any important information."

    static let emailPromptOutline = "Task: You must describe each name and entity mentioned in the meeting.\n\nWrite one sentence outlining the general purpose of the meeting\n\nBriefly mention the topics that were discussed, be very concise.\n\nDo not include Irrelevant details.\n\nHighlight the main conclusions and any action items that were agreed upon in bullets.\n\nInclude any deadlines or follow-up steps that were established during the meeting in bullets."

    static let emailPromptFollowUp = "TASK: You must write a quick follow-up email to “all” thanking them for meeting with you today. You must be extremely concise. The recipient of the email does not want to read more than a few sentences of text. You must highlight key points of the meeting in the email. You must place the key points in a list. You must write with an informal tone, be naturally flowing and creative. You must be human like, do not use complex words. Be professional. Be very concise. Be blunt."
}
