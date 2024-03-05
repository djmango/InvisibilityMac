//
//  OnboardingView.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 1/14/24.
//

import SwiftUI

struct OnboardingView: View {
    @State private var viewIndex: Int = 0

    @AppStorage("onboardingViewed") private var onboardingViewed = false
    @AppStorage("emailAddress") private var emailAddress: String = ""
    @AppStorage("analytics") private var analytics: Bool = true

    var body: some View {
        ZStack {
            // #212222
            // rgba(33,34,34,1)
            Color(red: 33 / 255, green: 34 / 255, blue: 34 / 255, opacity: 1).edgesIgnoringSafeArea(.all)

            switch viewIndex {
            case 0:
                OnboardingIntroView { viewIndex = 3 }

            // case 1:
            //     OnboardingExplainerView { viewIndex = 3 }

            // case 2:
            //     OnboardingEmailView { viewIndex = 3 }

            // case 3:
            //     OnboardingDownloadView {
            //         // viewIndex = 4
            //         onboardingViewed = true
            //     }

            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
