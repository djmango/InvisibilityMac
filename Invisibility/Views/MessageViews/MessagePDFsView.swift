//
//  MessagePDFsView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/16/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct MessagePDFsView: View {
    private let items: [Data]

    init(items: [Data]) {
        self.items = items
    }

    var body: some View {
        ForEach(items, id: \.self) { _ in
            Image("PDFIcon")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150)
                .padding(.horizontal, 10)
                .shadow(radius: 2)
        }
    }
}
