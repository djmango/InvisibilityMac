//
//  SettingsUserCardView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/14/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import CachedAsyncImage
import SwiftUI

struct SettingsUserCardView: View {
    @ObservedObject private var userManager = UserManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isHoveringUserDetails = false
    @State private var isCopied = false
    @State private var shareButtonView: NSView?
    
    var friendsInvitedText: String {
        if userManager.inviteCount == 0 {
            "No friends invited yet :("
        } else {
            "\(userManager.inviteCount) friend" + (userManager.inviteCount > 1 ? "s invited!" : " invited!")
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            header
                .whenHovered { hovering in
                    withAnimation(AppConfig.snappy) {
                        isHoveringUserDetails = hovering
                    }
                }
            
            // QR Code for the link
            QRView(string: userManager.inviteLink)
                .frame(width: 80, height: 80)
                .shadow(radius: 2)
                .padding(.top, 10)
            
            linkProfile
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            
            linkActionButtons
            subscriptionSection
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .padding(.top, 8)
        }
        .frame(width: 256)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.chatButtonBackground))
                .stroke(Color(nsColor: .separatorColor))
        )
        .visible(if: userManager.user != nil)
    }
    
    // MARK: - Header
    var header: some View {
        Group {
            profileImage
                .visible(if: userManager.user?.profilePictureUrl != nil)
            Text("\(userManager.user?.firstName ?? "") \(userManager.user?.lastName ?? "")")
                .font(.title3)
                .visible(if: userManager.user?.firstName != nil || userManager.user?.lastName != nil)
            
            Text(userManager.user?.email ?? "")
                .font(.caption)
            
            Text(userManager.isPaid ? "Invisibility Plus" : "Invisibility Free")
                .foregroundColor(userManager.isPaid ? .blue : .primary)
                .font(.caption)
                .italic()
            
            logoutButton
                .visible(if: isHoveringUserDetails, removeCompletely: true)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
        }
    }
    
    var profileImage: some View {
        CachedAsyncImage(url: URL(string: userManager.user?.profilePictureUrl ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(colorScheme == .dark ? .white : .black, lineWidth: 2))
                .padding(10)
        } placeholder: {
            ProgressView()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(colorScheme == .dark ? .white : .black), lineWidth: 2))
                .padding(10)
        }
    }
    
    var logoutButton: some View {
        Button(action: {
            UserManager.shared.logout()
        }) {
            Text("Logout")
                .font(.system(size: 13, weight: .light))
                .foregroundColor(.white)
                .padding(.vertical, 2)
                .padding(.horizontal, 14)
                .background(Color.blue)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor))
                )
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Link Section
    var linkActionButtons: some View {
        HStack {
            copyLinkButton
            shareLinkButton
                .background(ShareButtonView(nsView: $shareButtonView))
                .padding(.leading, 20)
        }
    }
    
    // Link is invite.i.inc/firstName
    var linkProfile: some View {
        Button(action: {
            // Open the invite link
            if let url = URL(string: userManager.inviteLink) {
                NSWorkspace.shared.open(url)
            }
        }) {
            Text("invite.i.inc/\(userManager.user?.firstName?.lowercased() ?? "")")
                .font(.body)
        }
        .buttonStyle(.link)
    }
    
    var copyLinkButton: some View {
        MessageButtonItemView(
            label: "Copy",
            icon: isCopied ? "checkmark" : "square.on.square",
            shortcut_hint: .none,
            size: 12
        ) {
            onCopyReferralLink()
        }
    }
    
    var shareLinkButton: some View {
        MessageButtonItemView(
            label: "Share",
            icon: "square.and.arrow.up",
            shortcut_hint: .none,
            size: 12
        ) {
            if let view = shareButtonView {
                onShareButtonClicked(sender: view)
            }
        }
    }
    
    // MARK: - Subscription Section
    var subscriptionSection: some View {
        VStack {
            manageButton
                .visible(if: userManager.isPaid, removeCompletely: true)
            upgradeButton
                .visible(if: !userManager.isPaid, removeCompletely: true)
        }
    }
    
    // Manage
    var manageButton: some View {
        subscriptionActionButtonView(title: "Manage", action: { UserManager.shared.manage()})
    }
    
    // Upgrade
    var upgradeButton: some View {
        subscriptionActionButtonView(title: "Upgrade", action: { UserManager.shared.pay()})
    }
    
    // MARK: - Helper Functions
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

#Preview {
    SettingsUserCardView()
}
