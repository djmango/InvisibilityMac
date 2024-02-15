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
        let calendar = Calendar.autoupdatingCurrent

        // Create the date components
        var nowComponents = DateComponents()
        nowComponents.day = 0
        let now = calendar.date(byAdding: nowComponents, to: Date(), wrappingComponents: false)

        var oneDayFromNowComponents = DateComponents()
        oneDayFromNowComponents.day = 1
        let oneDayFromNow = calendar.date(byAdding: oneDayFromNowComponents, to: Date(), wrappingComponents: false)

        // Create the predicate from the event store's instance method.
        var predicate: NSPredicate? = nil
        if let anAgo = now, let aNow = oneDayFromNow {
            predicate = self.eventStore.predicateForEvents(withStart: anAgo, end: aNow, calendars: nil)
        }

        // Fetch all events that match the predicate.
        if let aPredicate = predicate {
            let events = self.eventStore.events(matching: aPredicate)

            var filteredEvents: [EKEvent] = []
            for event in events {
                if event.isAllDay {
                    continue
                }

                filteredEvents.append(event)
            }

            self.logger.debug("Fetched \(self.events.count) events")
            for event in self.events {
                self.logger.debug("Event: \(event.title ?? "No Title")")
            }

            DispatchQueue.main.async {
                self.events = filteredEvents
            }
        }
    }
}
