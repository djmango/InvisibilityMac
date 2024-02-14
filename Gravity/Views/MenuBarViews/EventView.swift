//
//  EventView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/13/24.
//

import SwiftUI

struct EventsView: View {
    @ObservedObject var viewModel = EventsViewModel()

    var body: some View {
        Text("Events")
        List(viewModel.events, id: \.eventIdentifier) { event in
            Button(event.title ?? "No Title") {
                if let url = event.url {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .onAppear {
            viewModel.requestAccessIfNeeded()
            viewModel.fetchEvents()
        }
    }
}
