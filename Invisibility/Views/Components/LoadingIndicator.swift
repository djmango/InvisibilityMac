import SwiftUI

struct LoadingIndicator: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.accentColor, lineWidth: 2)
                .frame(width: 24, height: 24)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

struct LoadingOverlay: View {
    let message: String
    let isLoading: Bool
    let content: AnyView
    
    init(message: String = "", isLoading: Bool, @ViewBuilder content: () -> some View) {
        self.message = message
        self.isLoading = isLoading
        self.content = AnyView(content())
    }
    
    var body: some View {
        ZStack {
            content
                .opacity(isLoading ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isLoading)
            
            if isLoading {
                LoadingIndicator(message: message)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingIndicator(message: "Loading...")
        
        LoadingOverlay(message: "Processing...", isLoading: true) {
            Text("Content behind loading overlay")
                .frame(width: 200, height: 100)
                .background(Color.gray.opacity(0.2))
        }
    }
    .padding()
} 
