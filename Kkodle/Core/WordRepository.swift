//
//  WordRepository.swift
//  Kkodle
//
//  Created by 장주진 on 7/25/26.
//

import Foundation

struct WordRepository {
    let answers: Set<String>
    let validGuesses: Set<String>

    init(atomCount: Int, bundle: Bundle = .main) {
        answers = Self.loadWordSet(fileName: "answers_\(atomCount)", bundle: bundle)
        validGuesses = Self.loadWordSet(fileName: "validGuesses_\(atomCount)", bundle: bundle)
    }

    func todayAnswer(referenceDate: Date = Date()) -> String? {
        let sorted = answers.sorted()
        guard !sorted.isEmpty else { return nil }
        let daysSinceEpoch = Int(referenceDate.timeIntervalSince1970 / 86400)
        return sorted[daysSinceEpoch % sorted.count]
    }

    private static func loadWordSet(fileName: String, bundle: Bundle) -> Set<String> {
        guard let url = bundle.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let words = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(words)
    }
}
