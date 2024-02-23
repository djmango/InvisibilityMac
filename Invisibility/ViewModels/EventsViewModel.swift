//
//  EventsViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/13/24.
//

import Combine
import EventKit
import Foundation
import OSLog
import SwiftUI

class EventsViewModel: ObservableObject {
    private let logger = Logger(subsystem: "ai.grav.app", category: "EventsViewModel")
    private let eventStore = EKEventStore()

    @Published var events: [EKEvent] = []
    @Published var nextEvent: EKEvent?

    private var timerSubscription: AnyCancellable?

    init() {
        requestAccessIfNeeded()
        startEventsRefreshTimer()
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

    func startEventsRefreshTimer() {
        // Cancel any existing timer
        timerSubscription?.cancel()

        // Create a new timer that fires every 10 minutes
        timerSubscription = Timer.publish(every: 600, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.fetchEvents()
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
            var filteredEvents: [EKEvent] = []
            for event in self.eventStore.events(matching: aPredicate) {
                if event.isAllDay {
                    continue
                }

                filteredEvents.append(event)
            }

            self.logger.debug("Fetched \(filteredEvents.count) events")

            DispatchQueue.main.async {
                self.nextEvent = filteredEvents.first(where: { $0.endDate > Date() }) // Update nextEvent to the first upcoming event
                self.events = filteredEvents.sorted { $0.startDate < $1.startDate } // Sort events by startDate
                self.logger.debug("Next event: \(self.nextEvent?.title ?? "No upcoming events")")
            }
        }
    }
}
