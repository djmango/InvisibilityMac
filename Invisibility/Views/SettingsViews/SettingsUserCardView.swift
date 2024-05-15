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

    var body: some View {
        VStack(alignment: .center) {
            Group {
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

                Button(action: {
                    UserManager.shared.logout()
                }) {
                    Text("Logout")
                }
                .buttonStyle(.bordered)
                .visible(if: isHoveringUserDetails, removeCompletely: true)
            }
            .onHover { hovering in
                withAnimation(AppConfig.snappy) {
                    isHoveringUserDetails = hovering
                }
            }

            // QR Code for the link
            QRView(string: userManager.inviteLink)
                .frame(width: 50, height: 50)
                .shadow(radius: 2)
                .padding(.top, 10)

            // Link is invite.i.inc/firstName
            Button(action: {
                // Open the invite link
                if let url = URL(string: userManager.inviteLink) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text("invite.i.inc/\(userManager.user?.firstName?.lowercased() ?? "")")
                    .font(.caption)
            }
            .buttonStyle(.link)

            Text("\(userManager.inviteCount) friends invited")
                .font(.caption)
                .padding(.bottom, 10)

            Button(action: {
                UserManager.shared.manage()
            }) {
                Text("Manage")
                    .foregroundColor(userManager.isPaid ? .primary : .blue)
            }
            .buttonStyle(.bordered)
            .visible(if: userManager.isPaid, removeCompletely: true)

            // Upgrade
            Button(action: {
                UserManager.shared.pay()
            }) {
                Text("Upgrade")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
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
            .visible(if: !userManager.isPaid, removeCompletely: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("ChatButtonBackgroundColor"))
                .shadow(radius: 2)
        )
        .visible(if: userManager.user != nil)
    }
}
