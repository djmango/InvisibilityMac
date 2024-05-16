//
//  ToastViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/15/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SimpleToast
import SwiftUI

final class ToastViewModel: ObservableObject {
    static let shared = ToastViewModel()

    @Published var showToast: Bool = false
    public var toastOptions = SimpleToastOptions(
        hideAfter: 3
    )
    public var title: String = ""
    public var icon: String = ""

    private init() {}

    func showToast(
        title: String,
        icon: String = "exclamationmark.triangle"
    ) {
        self.title = title
        self.icon = icon
        DispatchQueue.main.async {
            self.showToast = true
        }
    }
}
