//
//  WordComparer.swift
//  Kkodle
//
//  Created by 장주진 on 7/24/26.
//

import Foundation

enum WordComparer {
    static let atomCount = 5

    enum ComparisonError: Error {
        case invalidLength
    }

    static func compare(guess: [Character], answer: [Character]) throws -> [LetterHint] {
        guard guess.count == atomCount, answer.count == atomCount else {
            throw ComparisonError.invalidLength
        }

        var hints = [LetterHint](repeating: .absent, count: atomCount)
        var isExactMatch = [Bool](repeating: false, count: atomCount)

        for index in 0..<atomCount where guess[index] == answer[index] {
            hints[index] = .correct
            isExactMatch[index] = true
        }

        var remainingAtoms: [Character: Int] = [:]
        for index in 0..<atomCount where !isExactMatch[index] {
            remainingAtoms[answer[index], default: 0] += 1
        }

        for index in 0..<atomCount where !isExactMatch[index] {
            let atom = guess[index]
            if let count = remainingAtoms[atom], count > 0 {
                remainingAtoms[atom] = count - 1
                hints[index] = .present
            }
        }

        return hints
    }
}
