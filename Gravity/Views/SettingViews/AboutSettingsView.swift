//
//  AboutSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        VStack {
            Spacer()

            // Logo or image view placeholder
            Image(systemName: "eye") // Replace with your logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)

            Text("Founded by Sulaiman Ghori and Tye Daniel")
                .font(.headline)
                .padding(.top, 20)

            // Buttons for feedback, acknowledgments, and privacy
            HStack {
                Button("Feedback") {
                    // Action for feedback
                }
                .buttonStyle(PlainButtonStyle())

                Button("Acknowledgments") {
                    // Action for acknowledgments
                }
                .buttonStyle(PlainButtonStyle())

                Button("Privacy") {
                    // Action for privacy
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 10)

            Spacer()
        }
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 150, maxHeight: .infinity)
        .padding()
    }
}
