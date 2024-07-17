//
//  MouseEventManager.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/17/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import Cocoa

class MouseEventManager {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "MouseEventManager")

    static let shared = MouseEventManager()

    private var monitor: Any?
    var mouseX: CGFloat = 0
    var mouseY: CGFloat = 0
    
    // Track scroll events
    private var cumulativeScrollX: CGFloat = 0.0
    private var cumulativeScrollY: CGFloat = 0.0
    private var scrollStartTime: Double = 0.0
    
    // Track drag events
    private var cumulativeDragDistanceX: CGFloat = 0.0
    private var cumulativeDragDistanceY: CGFloat = 0.0
    
    func startTrackingMouseEvents() {
        guard monitor == nil else { return }
        
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseUp, .rightMouseUp, .scrollWheel, .leftMouseDragged, .rightMouseDragged]) { event in
            switch event.type {
            case .mouseMoved:
                let mouseLocation = event.locationInWindow
                self.mouseX = mouseLocation.x
                self.mouseY = mouseLocation.y
                break
                
            case .leftMouseUp:
                self.logger.info("left click: \(self.mouseX), \(self.mouseY)")
                break
                
            case .rightMouseUp:
                self.logger.info("right click: \(self.mouseX), \(self.mouseY)")
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
                    self.cumulativeScrollX = 0.0
                    self.cumulativeScrollY = 0.0
                    self.scrollStartTime = Date().timeIntervalSince1970
                    break
                case .changed:
                    // Accumulate scroll delta
                    self.cumulativeScrollX += event.scrollingDeltaX
                    self.cumulativeScrollY += event.scrollingDeltaY
                    break
                case .ended, .cancelled:
                    // Print accumulated scroll values
                    let scrollDuration = Date().timeIntervalSince1970 - self.scrollStartTime
                    self.logger.info("Total scrolled - X: \(self.cumulativeScrollX), Y: \(self.cumulativeScrollY). Duration: \(scrollDuration)s")
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
