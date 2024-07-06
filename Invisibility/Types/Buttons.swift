//
//  Buttons.swift
//  Invisibility
//
//  Created by minjune Song on 6/20/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI

enum HoverItemType {
    case nil_
    
    case chatImage
    case chatImageDelete
    
    case chatPDF
    case chatPDFDelete
    
    case menuItem
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

struct Collapsible<Content: View>: View {
    @State private var collapsed: Bool = true
    
    private var label: String
    private var content: () -> Content
    
    init(collapsed: Bool, label: String, content: @escaping () -> Content) {
        self.collapsed = collapsed
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack {
            Button(action: { self.collapsed.toggle() }) {
                HStack {
                    Text(self.label)
                    
                    Spacer()
                    
                    Image(systemName: self.collapsed ? "chevron.right" : "chevron.down")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(nsColor: .separatorColor))
                )
            }
            .buttonStyle(.plain)
            
            if !collapsed {
                self.content()
                    .padding(.horizontal, 8)
                    .frame(width: 300)
            }
        }
        .animation(AppConfig.easeInOut)
        .padding(.bottom, collapsed ? 0 : 8)
        .frame(width: 300)
        .background(Color.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(nsColor: .separatorColor))
        )
        .cornerRadius(4)
    }
}
