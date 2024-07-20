//
//  EventManager.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/17/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//


import Foundation
import Cocoa
import Alamofire

enum MouseAction: String, Codable {
    case left = "left"
    case right = "right"
    case middle = "middle"
    case button4 = "button4"
    case button5 = "button5"
}

struct ScrollAction: Codable {
    let x: Int
    let y: Int
    let duration: Int64
}

enum EventType {
    case mouse(MouseAction)
    case keyboard
    case scroll(ScrollAction)
}

class EventManager {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MouseEventManager")
    private let userManager: UserManager = .shared
    private let videoWriter: VideoWriter = .shared

    static let shared = EventManager()

    private var monitor: Any?
    var mouseX: CGFloat = 0
    var mouseY: CGFloat = 0
    
    // Track scroll events
    private var cumulativeScrollX: Int = 0
    private var cumulativeScrollY: Int = 0
    private var scrollStartTime: Double = 0.0
    
    private func recordEvent(eventType: EventType, timestamp: Int64) async {
        let urlString = AppConfig.invisibility_api_base + "/devents/create"
        guard let clipId = videoWriter.getCurrentClipId() else { return }
        guard let jwtToken = userManager.token else {
            logger.warning("No JWT token")
            return
        }
        
        do {
            let devent = try await withCheckedThrowingContinuation { continuation in
                var body: [String: Any] = [
                    "recording_id": clipId,
                    "session_id": userManager.sessionId,
                    "event_timestamp": timestamp,
                    "mouse_x": Int32(mouseX),
                    "mouse_y": Int32(mouseY),
                ]
                
                do {
                    switch eventType {
                    case .mouse(let action):
                        body["mouse_action"] = action.rawValue
                        break
                    case .scroll(let action):
                        let json = try JSONEncoder().encode(action)
                        if let dict = try JSONSerialization.jsonObject(with: json, options: .mutableContainers) as? [String: Any] {
                            body["scroll_action"] = dict
                        }
                        break
                    default:
                        return
                    }
                } catch {
                    self.logger.error("Error encoding scroll action: \(error)")
                }
                
//                logger.info("body: \(body)")
                                
                AF.request(urlString, method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Authorization": "Bearer \(jwtToken)"])
                    .validate()
                    .responseString() { response in
                        switch response.result {
                        case let .success(devent):
                            continuation.resume(returning: devent)
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
            }
            
            logger.info("logged event: \(devent)")
        } catch {
            self.logger.error("Error logging event: \(error)")
            return
        }
    }
    
    func startTrackingMouseEvents() {
        guard monitor == nil else { return }

        let initialMouseLocation = NSEvent.mouseLocation
        self.mouseX = initialMouseLocation.x
        self.mouseY = initialMouseLocation.y
        logger.info("Initial mouse position: (\(self.mouseX), \(self.mouseY))")
        
        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .scrollWheel, .leftMouseDragged, .rightMouseDragged]) { event in
            switch event.type {
            case .mouseMoved:
                let mouseLocation = event.locationInWindow
                self.mouseX = mouseLocation.x
                self.mouseY = mouseLocation.y
                break
                
            case .leftMouseDown:
                Task {
                    await self.recordEvent(eventType: EventType.mouse(MouseAction.left), timestamp: Int64(Date().timeIntervalSince1970))
                }
                break
                
            case .rightMouseDown:
                Task {
                    await self.recordEvent(eventType: EventType.mouse(MouseAction.right), timestamp: Int64(Date().timeIntervalSince1970))
                }
                break
            
            case .leftMouseDragged:
                let mouseLocation = event.locationInWindow
                self.mouseX = mouseLocation.x
                self.mouseY = mouseLocation.y
                break

            case .rightMouseDragged:
                let mouseLocation = event.locationInWindow
                self.mouseX = mouseLocation.x
                self.mouseY = mouseLocation.y
                break

                
            case .scrollWheel:
                switch event.phase {
                case .began:
                    // Start tracking
                    self.cumulativeScrollX = 0
                    self.cumulativeScrollY = 0
                    self.scrollStartTime = Date().timeIntervalSince1970
                    break
                case .changed:
                    // Accumulate scroll delta
                    self.cumulativeScrollX += Int(event.scrollingDeltaX)
                    self.cumulativeScrollY += Int(event.scrollingDeltaY)
                    break
                case .ended, .cancelled:
                    // Print accumulated scroll values
                    let scrollDuration = Date().timeIntervalSince1970 - self.scrollStartTime
                    Task {
                        await self.recordEvent(eventType: EventType.scroll(ScrollAction(x: self.cumulativeScrollX, y: self.cumulativeScrollY, duration: Int64(scrollDuration * 1000))), timestamp: Int64(self.scrollStartTime))
                    }
                    break
                default:
                    break
                }
                
                break
                
            default:
                break
            }
        }
    }
    
    func stopTrackingMouseEvents() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
