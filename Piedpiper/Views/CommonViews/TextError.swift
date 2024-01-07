import SwiftUI

struct TextError: View {
    private var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foregroundStyle(.red)
    }
}

#Preview {
    TextError(AppMessages.generalErrorMessage)
}
