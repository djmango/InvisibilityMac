//
//  FuzzySearchType.swift
//  Invisibility
//
//  Created by Duy Khang Nguyen Truong on 7/18/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

struct FuzzySearchMatchResult {
    let weight: Int
    let matchedParts: [NSRange]
}

struct FuzzySearchCharacter {
    let content: String
    let normalisedContent: String
}

struct FuzzySearchString {
    var characters: [FuzzySearchCharacter]
}
