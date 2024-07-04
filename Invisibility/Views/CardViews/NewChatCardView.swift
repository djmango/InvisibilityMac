//
//  NewChatCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 6/25/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

import SwiftUI

struct NewChatCardView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var isRefreshAnimating = false
    @State private var isCopied = false
    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0

    var body: some View {
        VStack (alignment: .leading) {
            Text("Start a new chat with Invisibility")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tips:")
                .font(.title3)
                .fontWeight(.medium)
                .padding(.top, 12)
                .padding(.bottom, 2)
            
            VStack (alignment: .leading, spacing: 4) {
                BulletPoint(text: "Turn on Sidekick (`⌘ ⇧ 2`) to share your screen with Invisibility.")
                BulletPoint(text: "Enter Setting (`⌘ ,`) to change which LLM Invisibility uses to generate responses.")
                BulletPoint(text: "Use the Memory tab (`⌘ M`) to view and edit what Invisibility remembers about you.")
            }
        }
        .padding(.vertical, 32)
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

struct BulletPoint: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("•")
            
            Text(text)
                .multilineTextAlignment(.leading)
        }
        .padding(.leading, 8)
    }
}

#Preview {
    NewChatCardView()
}
