//
//  FreeTierCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/14/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct FreeTierCardView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var isRefreshAnimating = false
    @State private var isCopied = false
    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0

    var friendsInvitedText: String {
        if userManager.inviteCount == 0 {
            "No friends invited yet :("
        } else {
            "\(userManager.inviteCount) friend" + (userManager.inviteCount > 1 ? "s invited!" : " invited!")
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            Spacer()

            Text("Invite friends to Invisibility 💙")
                .font(.title3)
                .fontWeight(.bold)

            Text("Earn 20 messages for every friend you invite! 🎉")
                .font(.body)
                .foregroundColor(.gray)

            // Link is invite.i.inc/firstName
            Button(action: {
                if let url = URL(string: "https://invite.i.inc/\(userManager.user?.firstName ?? "")") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text("invite.i.inc/\(userManager.user?.firstName?.lowercased() ?? "")")
                    .font(.title2)
            }
            .buttonStyle(.link)

            QRView(string: userManager.inviteLink)
                .frame(width: 80, height: 80)
                .shadow(radius: 2)

            Text(friendsInvitedText)
                .font(.callout)
                .foregroundColor(.gray)

            Text("\(numMessagesSentToday)/\(userManager.numMessagesAllowed) messages sent today")
                .font(.callout)
                .foregroundColor(.gray)

            Text("Or")
                .font(.title3)
                .fontWeight(.bold)

            Button(action: {
                UserManager.shared.pay()
            }) {
                Text("Get Free Trial")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 28)
                    .background(Color.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor))
                    )
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .shadow(radius: 2)

            Text("Unlimited messages, early access, and more!")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
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
        .frame(maxWidth: .infinity)
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
