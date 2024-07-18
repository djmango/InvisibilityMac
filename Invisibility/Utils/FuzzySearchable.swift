//
//  FuzzySearchable.swift
//  Invisibility
//
//  Created by Duy Khang Nguyen Truong on 7/18/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation

protocol FuzzySearchable {
    var searchableString: String { get }

    func fuzzyMatch(query: String, characters: FuzzySearchString) -> FuzzySearchMatchResult
}

extension FuzzySearchable {
    func fuzzyMatch(query: String, characters: FuzzySearchString) -> FuzzySearchMatchResult {
        let compareString = characters.characters // the string we compare against
        let searchString = query.lowercased() // make the query case-insensitive

        var totalScore = 0 // represents the weight of the match
        var matchedParts = [NSRange]() // Ranges that match compareString and searchString

        // This is always the data for one match
        var patternIndex = 0
        var currentScore = 0
        var currentMatchedPart = NSRange(location: 0, length: 0)

        for (index, character) in compareString.enumerated() {
            if let prefixLength = searchString.hasPrefix(prefix: character, startingAt: patternIndex) {
                // A match was found, so we increment the score and the range
                patternIndex += prefixLength
                currentScore += 1
                currentMatchedPart.length += 1
            } else {
                // No match was found
                currentScore = 0
                if currentMatchedPart.length != 0 {
                    matchedParts.append(currentMatchedPart)
                }
                currentMatchedPart = NSRange(location: index + 1, length: 0)
            }
            totalScore += currentScore
        }

        if currentMatchedPart.length != 0 {
            matchedParts.append(currentMatchedPart)
        }

        if searchString.count == matchedParts.reduce(0, { partialResults, range in
            range.length + partialResults
        }) {
            return FuzzySearchMatchResult(weight: totalScore, matchedParts: matchedParts)
        } else {
            return FuzzySearchMatchResult(weight: 0, matchedParts: [])
        }
    }
    
    func normaliseString() -> FuzzySearchString {
        return FuzzySearchString(characters: searchableString.normalise())
    }
    
    func fuzzyMatch(query: String) -> FuzzySearchMatchResult {
        let characters = normaliseString()
        
        return fuzzyMatch(query: query, characters: characters)
    }
}

extension Collection where Iterator.Element: FuzzySearchable {
    func fuzzySearch(query: String) -> [(result: FuzzySearchMatchResult, item: Iterator.Element)] {
        return map {
            (result: $0.fuzzyMatch(query: query), item: $0)
        }.filter {
            $0.result.weight > 0
        }.sorted {
            $0.result.weight > $1.result.weight
        }
    }
}
