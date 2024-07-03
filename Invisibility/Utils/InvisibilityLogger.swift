//
//  InvisibilityLogger.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/24/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog
import RollbarNotifier

struct InvisibilityLogger {
    private let logger: Logger
    private let subsystem: String
    private let category: String

    enum Level {
        case debug
        case info
        case warning
        case error
    }

    init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
        self.subsystem = subsystem
        self.category = category
    }

    private func log(_ message: String, level: Level, file _: String, function _: String, line _: Int) {
        switch level {
        case .debug:
            logger.debug("\(message)")
        // Rollbar.debugMessage(message)
        case .info:
            logger.info("\(message)")
            Rollbar.infoMessage(message)
        case .warning:
            logger.warning("\(message)")
            Rollbar.warningMessage(message)
        case .error:
            logger.error("\(message)")
            Rollbar.errorMessage(message)
        }
    }

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}
