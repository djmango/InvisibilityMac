//
//  Decoder.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 5/22/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

func iso8601Decoder() -> JSONDecoder {
    let decoder = JSONDecoder()

    // Define a custom DateFormatter
    let iso8601Formatter = DateFormatter()
    iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    iso8601Formatter.calendar = Calendar(identifier: .iso8601)
    iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
    iso8601Formatter.locale = Locale(identifier: "en_US_POSIX")

    // Set up the decoder with the custom date decoding strategy
    decoder.dateDecodingStrategy = .formatted(iso8601Formatter)

    return decoder
}

