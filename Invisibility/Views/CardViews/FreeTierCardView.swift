//
//  FreeTierCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/14/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Cocoa
import SwiftUI

struct FreeTierCardView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var isRefreshAnimating = false
    @State private var isCopied = false
    @State private var whoIsHovering: String?
    @State private var shareButtonView: NSView?
    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0

    var friendsInvitedText: String {
        if userManager.inviteCount == 0 {
            "No friends invited yet :("
        } else {
            "\(userManager.inviteCount) friend" + (userManager.inviteCount > 1 ? "s invited!" : " invited!")
        }
    }

    var body: some View {
        VStack {
            VStack {
                Text("Daily Limit Reached")
                    .font(.system(size: 24, weight: .bold))

                Text("\(numMessagesSentToday)/\(userManager.numMessagesAllowed) messages sent today")
                    .font(.body)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack {
                Text("Invite friends to unlock more messages!")
                    .padding(.top, 12)
                    .font(.title3)
                    .fontWeight(.semibold)

                QRView(string: userManager.inviteLink)
                    .frame(width: 100, height: 100)
                    .shadow(radius: 2)

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
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }

                HStack {
                    MessageButtonItemView(
                        label: "Copy",
                        icon: isCopied ? "checkmark" : "square.on.square",
                        shortcut_hint: .none
                    ) {
                        onCopyReferralLink()
                    }

                    MessageButtonItemView(
                        label: "Share",
                        icon: "square.and.arrow.up",
                        shortcut_hint: .none
                    ) {
                        if let view = shareButtonView {
                            onShareButtonClicked(sender: view)
                        }
                    }
                    .background(ShareButtonView(nsView: $shareButtonView))
                    .padding(.leading, 20)
                }
            }

            Spacer()

            Text("Or")
                .font(.body)

            Spacer()

            VStack {
                Text("Unlock unlimited access!")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Button(action: {
                    UserManager.shared.pay()
                }) {
                    Text("Start Free Trial")
                        .font(.system(size: 20, weight: .bold))
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
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            }
        }
        .frame(width: 360)
        .padding(.vertical)
        .cornerRadius(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor))
        )
        .background(
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
        )
        .onTapGesture {
            onTap()
        }
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                        .visible(if: isRefreshAnimating)
                        .padding(.vertical, 15)
                        .padding(.trailing, 12)
                }
                Spacer()
            }
        )
        .padding(.horizontal, 20)
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

    func onShareButtonClicked(sender: NSView) {
        let picker = NSSharingServicePicker(items: ["https://invite.i.inc/\(userManager.user?.firstName?.lowercased() ?? "")"])
        picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
}

struct ShareButtonView: NSViewRepresentable {
    @Binding var nsView: NSView?

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.nsView = view
        }
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}
