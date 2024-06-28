//
//  AnimationManager.swift
//  Invisibility
//
//  Created by minjune Song on 6/27/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    @Published var shouldAnimate = false
    
    func animate(_ action: @escaping () -> Void) {
        withAnimation(AppConfig.snappy) {
            shouldAnimate = true
            action()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Adjust timing as needed
            withAnimation(AppConfig.snappy) {
                self.shouldAnimate = false
            }
        }
    }
}
