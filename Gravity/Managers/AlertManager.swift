//
//  AlertViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/17/24.
//

import Combine
import Foundation
import SwiftUI

class AlertManager: ObservableObject {
    static let shared = AlertManager()

    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var alertDismissText: String = "OK"

    private init() {}

    func doShowAlert(title: String, message: String, dismissText: String = "OK") {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.alertDismissText = dismissText
            self.showAlert = true
        }
    }
}
