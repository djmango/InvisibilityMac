//
//  AlertViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/17/24.
//

import Combine
import Foundation
import SwiftUI

class AlertViewModel: ObservableObject {
    static let shared = AlertViewModel()
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var alertDismissText: String = "OK"

    func doShowAlert(title: String, message: String, dismissText: String = "OK") {
        alertTitle = title
        alertMessage = message
        alertDismissText = dismissText
        showAlert = true
    }
}
