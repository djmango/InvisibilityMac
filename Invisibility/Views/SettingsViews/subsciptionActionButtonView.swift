//
//  subsciptionActionButtonView.swift
//  Invisibility
//
//  Created by Duy Khang Nguyen Truong on 7/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct subscriptionActionButtonView: View {
    private let title: String
    private let action: () -> Void
    
    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
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
    }
}
