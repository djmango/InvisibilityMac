//
//  NewChatCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI
import MarkdownWebView

struct NewChatCardView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var isRefreshAnimating = false
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
        "Easily start a new chat by pressing `⌘ N`."
    ]
    
    init() {
        _currentTip = State(initialValue: getRandomTip())
    }

    private func getRandomTip() -> String {
        let randomIndex = Int.random(in: 0..<tips.count)
        return tips[randomIndex]
    }
    

    var body: some View {
        VStack (alignment: .leading) {
            Text("New Chat")
                .font(.title)
                .fontWeight(.semibold)
            
            VStack (alignment: .leading) {
                HStack (alignment: .center) {
                    Image(systemName: "lightbulb.max.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Text("Pro Tip:")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                MarkdownWebView(currentTip)
                    .font(.system(size: 14))
                    .padding(.leading, 16)
                    .padding(.top, -6)
            }
            .padding(.top, 8)
            
            Button(action: {
                if let view = shareButtonView {
                    let picker = NSSharingServicePicker(items: ["https://invite.i.inc/\(userManager.user?.firstName?.lowercased() ?? "")"])
                    picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
                }

            }) {
                Text("Share Invisibility with a friend!")
                    .font(.title2)
            }
            .padding(.top, 16)
            .buttonStyle(.link)
            .background(ShareButtonView(nsView: $shareButtonView))
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
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
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshAnimating ? 360 : 0))
                        .frame(width: 10, height: 10)
                        .opacity(isRefreshAnimating ? 1 : 0)
                        .padding(10)
                }
                Spacer()
            }
        )
        .onTapGesture {
            onTap()
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 3)
    }

    func onTap() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isRefreshAnimating = true
        }

        UserManager.shared.getInviteCount()
        // Set the animation state back to false after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isRefreshAnimating = false
        }
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
