//
//  DeventManager.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/17/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//


import Foundation
import Cocoa
import Alamofire

class DeventManager {
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "DeventManager")
    private let userManager: UserManager = .shared
    private let videoWriter: VideoWriter = .shared

    static let shared = DeventManager()

    private var monitor: Any?
    private var keyMonitor: CFMachPort?

    var mouseX: CGFloat = 0
    var mouseY: CGFloat = 0
    
    // Track scroll events
    private var cumulativeScrollX: Int = 0
    private var cumulativeScrollY: Int = 0
    private var scrollStartTime: Double = 0.0
    
    private func recordDevent(eventType: DeventType, timestamp: Double) async {
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
                    "event_timestamp_nanos": Int64(timestamp * 1_000_000_000),
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
                    case .keyboard(let action):
                        let json = try JSONEncoder().encode(action)
                        if let dict = try JSONSerialization.jsonObject(with: json, options: .mutableContainers) as? [String: Any] {
                            body["keyboard_action"] = dict
                        }
                        break
                    }
                } catch {
                    self.logger.error("Error encoding scroll action: \(error)")
                }
                
//                logger.info("body: \(body["event_timestamp"]), \(timestamp)")
                                         
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
            
//            logger.info("logged event: \(devent)")
        } catch {
            self.logger.error("Error logging event: \(error)")
            return
        }
    }
     
    func startTrackingDevents() {
        guard monitor == nil else { return }

        let initialMouseLocation = NSEvent.mouseLocation
        self.mouseX = initialMouseLocation.x
        self.mouseY = initialMouseLocation.y
        logger.info("Initial mouse position: (\(self.mouseX), \(self.mouseY))")
        
        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .scrollWheel, .leftMouseDragged, .rightMouseDragged, .keyDown]) { event in
            switch event.type {
            case .mouseMoved:
                let mouseLocation = event.locationInWindow
                self.mouseX = mouseLocation.x
                self.mouseY = mouseLocation.y
                break
                
            case .leftMouseDown:
                Task {
                    await self.recordDevent(eventType: DeventType.mouse(MouseAction.left), timestamp: Date().timeIntervalSince1970)
                }
                break
                
            case .rightMouseDown:
                Task {
                    await self.recordDevent(eventType: DeventType.mouse(MouseAction.right), timestamp: Date().timeIntervalSince1970)
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
                
            case .keyDown:
                let flags = event.modifierFlags
                let keyCode = event.keyCode
                
                Task {
                    var modifiers: [ModifierKey] = []
                    
                    if flags.contains(.command) {
                        modifiers.append(ModifierKey.command)
                    }
                    if flags.contains(.option) {
                        modifiers.append(ModifierKey.option)
                    }
                    if flags.contains(.control) {
                        modifiers.append(ModifierKey.control)
                    }
                    if flags.contains(.shift) {
                        modifiers.append(ModifierKey.shift)
                    }
                    if flags.contains(.capsLock) {
                        modifiers.append(ModifierKey.capsLock)
                    }
                    if flags.contains(.function) {
                        modifiers.append(ModifierKey.fn)
                    }
                    
                    if let key = KeyboardActionKey.from(keyCode: keyCode) {
                        await self.recordDevent(eventType: DeventType.keyboard(KeyboardAction(key: key, modifiers: modifiers)), timestamp: Date().timeIntervalSince1970)
                    } else {
                        self.logger.warning("Unrecognized key code: \(keyCode)")
                    }
                }
                
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
                        await self.recordDevent(eventType: DeventType.scroll(ScrollAction(x: self.cumulativeScrollX, y: self.cumulativeScrollY, duration: Int64(scrollDuration * 1000))), timestamp: self.scrollStartTime)
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
    
    func stopTrackingDevents() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        
        if let keyMonitor = keyMonitor {
            CGEvent.tapEnable(tap: keyMonitor, enable: false)
            self.keyMonitor = nil
        }
    }
}


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

enum ModifierKey: String, Codable {
    case capsLock = "caps_lock"
    case shift = "shift"
    case command = "command"
    case option = "option"
    case control = "control"
    case fn = "fn"
    case alt = "alt"
    case meta = "meta"
}

enum KeyboardActionKey: String, Codable  {
    // Function Keys
    case f1 = "f1"
    case f2 = "f2"
    case f3 = "f3"
    case f4 = "f4"
    case f5 = "f5"
    case f6 = "f6"
    case f7 = "f7"
    case f8 = "f8"
    case f9 = "f9"
    case f10 = "f10"
    case f11 = "f11"
    case f12 = "f12"
    // Alphabet Keys
    case a = "a"
    case b = "b"
    case c = "c"
    case d = "d"
    case e = "e"
    case f = "f"
    case g = "g"
    case h = "h"
    case i = "i"
    case j = "j"
    case k = "k"
    case l = "l"
    case m = "m"
    case n = "n"
    case o = "o"
    case p = "p"
    case q = "q"
    case r = "r"
    case s = "s"
    case t = "t"
    case u = "u"
    case v = "v"
    case w = "w"
    case x = "x"
    case y = "y"
    case z = "z"
    // Number Keys
    case num0 = "0"
    case num1 = "1"
    case num2 = "2"
    case num3 = "3"
    case num4 = "4"
    case num5 = "5"
    case num6 = "6"
    case num7 = "7"
    case num8 = "8"
    case num9 = "9"
    // Navigation Keys
    case arrowUp = "arrow_up"
    case arrowDown = "arrow_down"
    case arrowLeft = "arrow_left"
    case arrowRight = "arrow_right"
    case home = "home"
    case end = "end"
    case pageUp = "page_up"
    case pageDown = "page_down"
    // Special Keys
    case escape = "escape"
    case enter = "enter"
    case tab = "tab"
    case space = "space"
    case backspace = "backspace"
    case insert = "insert"
    case delete = "delete"
    case capsLock = "caps_lock"
    case numLock = "num_lock"
    case scrollLock = "scroll_lock"
    case pause = "pause"
    case printScreen = "print_screen"
    // Symbols
    case grave = "grave"
    case minus = "minus"
    case equals = "equals"
    case bracketLeft = "bracket_left"
    case bracketRight = "bracket_right"
    case semicolon = "semicolon"
    case quote = "quote"
    case comma = "comma"
    case period = "period"
    case slash = "slash"
    case backslash = "backslash"
    
    static func from(keyCode: UInt16) -> KeyboardActionKey? {
        switch keyCode {
        case 0x00: return .a
        case 0x01: return .s
        case 0x02: return .d
        case 0x03: return .f
        case 0x04: return .h
        case 0x05: return .g
        case 0x06: return .z
        case 0x07: return .x
        case 0x08: return .c
        case 0x09: return .v
        case 0x0B: return .b
        case 0x0C: return .q
        case 0x0D: return .w
        case 0x0E: return .e
        case 0x0F: return .r
        case 0x10: return .y
        case 0x11: return .t
        case 0x12: return .num1
        case 0x13: return .num2
        case 0x14: return .num3
        case 0x15: return .num4
        case 0x16: return .num6
        case 0x17: return .num5
        case 0x18: return .equals
        case 0x19: return .num9
        case 0x1A: return .num7
        case 0x1B: return .minus
        case 0x1C: return .num8
        case 0x1D: return .num0
        case 0x1E: return .bracketRight
        case 0x1F: return .o
        case 0x20: return .u
        case 0x21: return .bracketLeft
        case 0x22: return .i
        case 0x23: return .p
        case 0x24: return .enter
        case 0x25: return .l
        case 0x26: return .j
        case 0x27: return .quote
        case 0x28: return .k
        case 0x29: return .semicolon
        case 0x2A: return .backslash
        case 0x2B: return .comma
        case 0x2C: return .slash
        case 0x2D: return .n
        case 0x2E: return .m
        case 0x2F: return .period
        case 0x30: return .tab
        case 0x31: return .space
        case 0x32: return .grave
        case 0x33: return .backspace
        case 0x35: return .escape
        case 0x60: return .f5
        case 0x61: return .f6
        case 0x62: return .f7
        case 0x63: return .f3
        case 0x64: return .f8
        case 0x65: return .f9
        case 0x67: return .f11
        case 0x6D: return .f10
        case 0x6F: return .f12
        case 0x73: return .home
        case 0x74: return .pageUp
        case 0x75: return .delete
        case 0x76: return .f4
        case 0x77: return .end
        case 0x78: return .f2
        case 0x79: return .pageDown
        case 0x7A: return .f1
        case 0x7B: return .arrowLeft
        case 0x7C: return .arrowRight
        case 0x7D: return .arrowDown
        case 0x7E: return .arrowUp
        default: return nil
        }
    }
}

struct KeyboardAction: Codable {
    let key: KeyboardActionKey
    let modifiers: [ModifierKey]
}

enum DeventType {
    case mouse(MouseAction)
    case keyboard(KeyboardAction)
    case scroll(ScrollAction)
}
