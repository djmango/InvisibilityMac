//
//  EventView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/13/24.
//

import SwiftUI

struct EventsView: View {
    @StateObject var viewModel = EventsViewModel()

    var body: some View {
        ForEach(viewModel.events, id: \.eventIdentifier) { event in
            HStack {
                Button(event.title ?? "No Title") {
                    if let url = event.url {
                        NSWorkspace.shared.open(url)
                    } else if let url = URL(string: event.location ?? "") {
                        if url.absoluteString.isValidURL() {
                            NSWorkspace.shared.open(url)
                        } else {
                            AlertManager.shared.doShowAlert(
                                title: "Location",
                                message: "Location for \(event.title ?? "No Title") is \(event.location ?? "not included in the event")"
                            )
                        }
                    } else {
                        AlertManager.shared.doShowAlert(title: "No URL", message: "No URL for event \(event.title ?? "No Title")")
                    }
                }
                .buttonStyle(.accessoryBar)
                .selectionDisabled()

                Text(event.startDate?.formatted() ?? "No Date")
                Divider()
            }
        }
        .onAppear {
            viewModel.requestAccessIfNeeded()
            viewModel.fetchEvents()
        }
    }
}
