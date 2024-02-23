//
//  OnboardingEmailView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import SwiftUI

struct OnboardingEmailView: View {
    private var callback: () -> Void

    @AppStorage("emailAddress") private var emailAddress: String = ""
    @AppStorage("analytics") private var analytics: Bool = true

    init(callback: @escaping () -> Void = {}) {
        self.callback = callback
    }

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text("Let's keep in touch")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 50)

                Text("This way, we can help you with issues. We promise, we'll never send you spam.")
                    .font(.system(size: 15))
                    .bold()
                    // #B3B3B3
                    .foregroundColor(Color(red: 179 / 255, green: 179 / 255, blue: 179 / 255, opacity: 1))
                    .padding(.top, 10)

                TextField("Enter your email (optional)", text: $emailAddress)
                    .frame(width: 300, height: 50)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20))
                    .padding(.horizontal, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.accent, lineWidth: 1)
                    )
                    .padding(.top, 10)

                Toggle(isOn: $analytics) {
                    Text("Share anonymous crash reports and analytics")
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)

                Spacer()

                Button(action: callback) {
                    Text("Continue")
                        .font(.system(size: 18))
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .frame(width: 200, height: 50)
                .buttonStyle(.plain)
                .background(.accent)
                .cornerRadius(25)
                .padding()
                .focusable(false)
                .onTapGesture(perform: callback)
                .onHover { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingEmailView()
}
