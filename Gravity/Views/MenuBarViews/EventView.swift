//
//  EventView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/13/24.
//

import SwiftUI

struct EventsView: View {
    @StateObject var viewModel = EventsViewModel()
    @ObservedObject private var screenRecorder = ScreenRecorder.shared

    @State private var eventIsHovered = false
    @State private var recordingIsHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Next event title and button to join
            HStack {
                Button(action: {
                    if let url = viewModel.nextEvent?.url {
                        NSWorkspace.shared.open(url)
                    } else if let url = URL(string: viewModel.nextEvent?.location ?? "") {
                        if url.absoluteString.isValidURL() {
                            NSWorkspace.shared.open(url)
                        } else {
                            AlertManager.shared.doShowAlert(
                                title: "Location",
                                message: "Location for \(self.viewModel.nextEvent?.title ?? "No Title") is \(self.viewModel.nextEvent?.location ?? "not included in the event")"
                            )
                        }
                    } else {
                        AlertManager.shared.doShowAlert(title: "No URL", message: "No URL for event \(self.viewModel.nextEvent?.title ?? "No Title")")
                    }
                }) {
                    Image(systemName: "calendar")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.primary)

                    Text(viewModel.nextEvent?.title ?? "No Title")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .bold()
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(eventIsHovered ? Color("MenuBarButtonColor") : .clear)
                    .padding(-5)
            )
            .padding(.top, 8)
            .onHover { hovering in
                eventIsHovered = hovering
            }

            // Record status/button and next event time
            HStack {
                Button(action: {
                    toggleRecording()

                }) {
                    Text(
                        screenRecorder.isRunning ? "◉ Recording" : "◉ Record"
                    )
                    .font(.title3)
                    .foregroundColor(screenRecorder.isRunning ? .red : .primary)
                }
                .keyboardShortcut("r", modifiers: .command)
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(screenRecorder.isRunning ? .red.opacity(0.1) : recordingIsHovered ? Color("MenuBarButtonColor") : .clear)
                        .padding(-5)
                )
                .onHover { hovering in
                    recordingIsHovered = hovering
                }

                Text("\(viewModel.nextEvent?.startDate?.formatted(date: .omitted, time: .shortened) ?? "No Date") - \(viewModel.nextEvent?.endDate?.formatted(date: .omitted, time: .shortened) ?? "No Date")")
                    .font(.title3)
            }
            .animation(.easeInOut(duration: 0.1), value: screenRecorder.isRunning)
            .padding(.top, 5)
            .padding(.bottom, 3)
        }
    }

    func toggleRecording() {
        if screenRecorder.isRunning {
            Task {
                await screenRecorder.stop()
            }
        } else {
            Task {
                await screenRecorder.start()
            }
        }
    }
}
