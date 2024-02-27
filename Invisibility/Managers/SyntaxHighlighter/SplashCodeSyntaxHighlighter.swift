//
//  SplashCodeSyntaxHighlighter.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/27/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import MarkdownUI
import Splash
import SwiftUI

struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>

    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }

    func highlightCode(_ content: String, language _: String?) -> Text {
        // guard language?.lowercased() == "swift" else {
        //   return Text(content)
        // }

        self.syntaxHighlighter.highlight(content)
    }
}

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
}
