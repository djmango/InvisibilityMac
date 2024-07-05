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
