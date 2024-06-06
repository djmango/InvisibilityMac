import OSLog
import Sparkle
import SwiftUI
import WhatsNewKit

struct AppView: View {
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "AppView")

    @ObservedObject private var toastViewModel = ToastViewModel.shared
    @AppStorage("onboardingViewed") private var onboardingViewed = false

    @State
    var whatsNew: WhatsNew? = WhatsNew(
        title: "WhatsNewKit",
        features: [
            .init(
                image: .init(
                    systemName: "star.fill",
                    foregroundColor: .orange
                ),
                title: "Showcase your new App Features",
                subtitle: "Present your new app features..."
            ),
            // ...
        ]
    )

    var body: some View {
        MainView()
            .pasteDestination(for: URL.self) { urls in
                guard let url = urls.first else { return }
                InvisibilityFileManager.handleFile(url)
            }
            .simpleToast(isPresented: $toastViewModel.showToast, options: toastViewModel.toastOptions) {
                HStack {
                    Image(systemName: toastViewModel.icon)
                        .foregroundColor(.yellow)
                    Text(toastViewModel.title)
                        .font(.title3)
                }
                .padding(15)
                .background(.background)
                .shadow(color: Color.black.opacity(0.3), radius: 2)
                .cornerRadius(16)
                .padding()
                .shadow(radius: 2)
            }
        // .sheet( whatsNew: self.$whatsNew)
        // .environment(
        //     \.whatsNew,
        //     WhatsNewEnvironment(
        //         // Specify in which way the presented WhatsNew Versions are stored.
        //         // In default the `UserDefaultsWhatsNewVersionStore` is used.
        //         // versionStore: UserDefaultsWhatsNewVersionStore(),
        //         versionStore: InMemoryWhatsNewVersionStore(),
        //         // Pass a `WhatsNewCollectionProvider` or an array of WhatsNew instances
        //         // whatsNewCollection: InvisibilityWhatsNew()
        //         whatsNewCollection: self
        //     )
        // )
        // .whatsNewSheet()
    }
}

// struct InvisibilityWhatsNew: WhatsNewCollectionProvider {
// extension AppView: WhatsNewCollectionProvider {
//     var whatsNewCollection: WhatsNewCollection {
//         WhatsNew(
//             version: "1.0.0",
//             // The title that is shown at the top
//             title: "What's New",
//             // The features you want to showcase
//             features: [
//                 WhatsNew.Feature(
//                     image: .init(systemName: "star.fill"),
//                     title: "Title",
//                     subtitle: "Subtitle"
//                 ),
//             ],
//             // The primary action that is used to dismiss the WhatsNewView
//             primaryAction: WhatsNew.PrimaryAction(
//                 title: "Continue",
//                 backgroundColor: .accentColor,
//                 foregroundColor: .white,
//                 onDismiss: {
//                     print("WhatsNewView has been dismissed")
//                 }
//             ),
//             // The optional secondary action that is displayed above the primary action
//             secondaryAction: WhatsNew.SecondaryAction(
//                 title: "Learn more",
//                 foregroundColor: .accentColor,
//                 // hapticFeedback: .selection,
//                 action: .openURL(
//                     .init(string: "https://github.com/SvenTiigi/WhatsNewKit")
//                 )
//             )
//         )
//         WhatsNew(
//             version: "1.1.0",
//             // The title that is shown at the top
//             title: "What's New",
//             // The features you want to showcase
//             features: [
//                 WhatsNew.Feature(
//                     image: .init(systemName: "star.fill"),
//                     title: "Title",
//                     subtitle: "Subtitle"
//                 ),
//             ],
//             // The primary action that is used to dismiss the WhatsNewView
//             primaryAction: WhatsNew.PrimaryAction(
//                 title: "Continue",
//                 backgroundColor: .accentColor,
//                 foregroundColor: .white,
//                 onDismiss: {
//                     print("WhatsNewView has been dismissed")
//                 }
//             ),
//             // The optional secondary action that is displayed above the primary action
//             secondaryAction: WhatsNew.SecondaryAction(
//                 title: "Learn more",
//                 foregroundColor: .accentColor,
//                 // hapticFeedback: .selection,
//                 action: .openURL(
//                     .init(string: "https://github.com/SvenTiigi/WhatsNewKit")
//                 )
//             )
//         )
//     }
// }
