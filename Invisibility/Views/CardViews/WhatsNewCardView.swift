//
//  WhatsNewCardView.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/3/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct WhatsNewCardView: View {
    @State private var isHovering = false

    var body: some View {
        ScrollView {
            VStack {
                Text("What's New in Invisibility")
                    .font(.title)
                    .fontWeight(.bold)

                newFeaturesList
                    .padding(.top, 32)

                Spacer()

                // Join discord button
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://discord.i.inc")!)
                }) {
                    Text("Join Discord")
                }
                .buttonStyle(.link)
                .padding(.top, 60)

                Button(action: {
                    MessageScrollViewModel.shared.hideWhatsNew()
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
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
                    isHovering = hovering
                    if hovering {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            }
            // .frame(minHeight: nil, maxHeight: nil)
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(nsColor: .separatorColor))
            )
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, cornerRadius: 16)
            )
            .padding(.horizontal, 10)
        }
    }

    var newFeaturesList: some View {
        VStack(alignment: .center, spacing: 16) {
            LazyVGrid(columns: [GridItem(.fixed(32), alignment: .center), GridItem(.flexible(minimum: 100, maximum: 400))], alignment: .leading, spacing: 20) {
                ForEach(AppConfig.whats_new_features, id: \.self) { feature in
                    Image(systemName: feature.iconName)
                        .foregroundColor(feature.iconColor)
                        .font(.system(size: 32))
                        .shadow(radius: 1)

                    VStack(alignment: .leading) {
                        Text(feature.title)
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                        Text(feature.description)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 16)
                }
            }
        }
    }
}

#Preview {
    WhatsNewCardView()
}
