//
//  StringExtensions.swift
//  Invisibility
//
//  Created by Duy Khang Nguyen Truong on 7/18/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

extension String {
    func normalise() -> [FuzzySearchCharacter] {
        return self.lowercased().map { char in
        guard let data = String(char).data(using: .ascii, allowLossyConversion: true), let normalisedCharacter = String(data: data, encoding: .ascii) else {
            return FuzzySearchCharacter(content: String(char), normalisedContent: String(char))
            }

        return FuzzySearchCharacter(content: String(char), normalisedContent: normalisedCharacter)
        }
    }
    
    func hasPrefix(prefix: FuzzySearchCharacter, startingAt index: Int) -> Int? {
            guard let stringIndex = self.index(self.startIndex, offsetBy: index, limitedBy: self.endIndex) else {
                return nil
            }
            let searchString = self.suffix(from: stringIndex)
            for prefix in [prefix.content, prefix.normalisedContent] where searchString.hasPrefix(prefix) {
                return prefix.count
            }
            return nil
        }
}
