//
//  String+extractedSubjects.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/19/24.
//

import Foundation

extension String {
    /// Finds and returns all strings matching the regular expression.
    func matchingStrings(regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(startIndex..., in: self))
            return results.compactMap {
                Range($0.range(at: 1), in: self).map { String(self[$0]) }
            }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
