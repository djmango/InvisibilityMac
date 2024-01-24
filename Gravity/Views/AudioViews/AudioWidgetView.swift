//
//  AudioWidgetView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import SwiftUI

struct AudioWidgetView: View {
    @State private var text: String = ""
    @State private var progress: Double = 0.5

    var body: some View {
        VStack {
            TextField("Auto-generated title", text: $text)
                .padding()
                .background(Color.gray.opacity(0.2)) // Adjust the color to match your UI
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.clear, lineWidth: 0) // No border
                )
                .foregroundColor(.white)

            // Your progress view at the bottom
            ProgressView(value: progress, total: 1)
                .accentColor(.blue) // Adjust the color to match your UI
                .frame(height: 20)
                .background(Color.black.opacity(0.2)) // Adjust the color to match your UI
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black) // Adjust the color to match your UI
    }
}
