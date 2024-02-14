//
//  EventsViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/13/24.
//

import EventKit
import Foundation
import OSLog
import SwiftUI

class EventsViewModel: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "EventsViewModel")
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []

    init() {
        requestAccessIfNeeded()
    }

    func requestAccessIfNeeded() {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted {
                self.fetchEvents()
            } else {
                self.logger.error("No access to calendar: \(error?.localizedDescription ?? "")")
                // Open the settings to allow access
                // NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
            }
        }
    }

    func fetchEvents() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate!, calendars: nil)

        DispatchQueue.main.async {
            self.events = self.eventStore.events(matching: predicate)
        }
    }
}
