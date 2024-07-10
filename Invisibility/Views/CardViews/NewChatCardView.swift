//
//  NewChatCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import MarkdownWebView
import SwiftUI

struct NewChatCardView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var isCopied = false
    @State private var shareButtonView: NSView?
    @State private var currentTip: String = ""

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0

    private let tips: [String] = [
        "Turn on Sidekick (`⌘ ⇧ 2`) to share your screen with Invisibility.",
        "Enter Setting (`⌘ ,`) to change which LLM Invisibility uses to generate responses.",
        "Use the Memory tab (`⌘ M`) to view and edit what Invisibility remembers about you.",
        "You can explore your chat history in the History tab (`⌘ F`).",
        "Press `⌥ Space` to easily open and close Invisibility.",
        "Easily start a new chat by pressing `⌘ N`.",
    ]

    init() {
        _currentTip = State(initialValue: getRandomTip())
    }

    private func getRandomTip() -> String {
        let randomIndex = Int.random(in: 0 ..< tips.count)
        return tips[randomIndex]
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Chat with Invisibility")
                .font(.title)
                .fontWeight(.semibold)
          
            tipMessage
                .padding(.top, 8)
            
            shareAppLink
                .padding(.top, 16)
                }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .cornerRadius(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 3)
    }
    
    var tipMessage: some View {
        VStack (alignment: .leading) {
            HStack (alignment: .center) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                
                Text("Pro Tip:")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 3)
            }
            
            MarkdownWebView(currentTip)
                .font(.system(size: 14))
                .padding(.leading, 2)
                .padding(.top, -6)
        }
    }
    
    var shareAppLink: some View {
        Button(action: {
            if let view = shareButtonView {
                let picker = NSSharingServicePicker(items: ["https://invite.i.inc/\(userManager.user?.firstName?.lowercased() ?? "")"])
                picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
            }

        }) {
            Text("Share Invisibility with a friend!")
                .font(.title2)
        }
        .buttonStyle(.link)
        .background(ShareButtonView(nsView: $shareButtonView))
    }

    func onCopyReferralLink() {
        // Copy the invite link to the clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("https://invite.i.inc/\(userManager.user?.firstName?.lowercased() ?? "")", forType: .string)
        isCopied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isCopied = false
        }
    }
}

#Preview {
    NewChatCardView()
}
