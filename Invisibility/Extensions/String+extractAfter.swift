//
//  String+extractAfter.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 2/19/24.
//

import Foundation

extension String {
    /// Extracts and returns the first matching string following a specified pattern.
    func extractAfter(pattern: String) -> String? {
        let regexPattern = "\(pattern)(.*)"
        if let regex = try? NSRegularExpression(pattern: regexPattern),
           let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) {
            let matchedRange = match.range(at: 1)
            if let range = Range(matchedRange, in: self) {
                return String(self[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}
