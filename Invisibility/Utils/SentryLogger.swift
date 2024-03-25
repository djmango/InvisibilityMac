//
//  SentryLogger.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/24/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import OSLog
import Sentry

struct SentryLogger {
    private let logger: Logger
    private let subsystem: String
    private let category: String

    init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
        self.subsystem = subsystem
        self.category = category
    }

    private func log(_ message: String, level: SentryLevel, file: String, function: String, line: Int) {
        let breadcrumb = Breadcrumb(level: level, category: category)
        let formattedMessage = "\(file):\(line) \(function) - \(message)"
        breadcrumb.message = formattedMessage
        SentrySDK.addBreadcrumb(breadcrumb)

        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
            SentrySDK.capture(message: message)
        case .fatal:
            logger.fault("\(message)")
            SentrySDK.capture(message: message)
        default:
            logger.info("\(message)")
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

    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fatal, file: file, function: function, line: line)
    }
}
