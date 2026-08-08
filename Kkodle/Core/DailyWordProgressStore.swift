//
//  DailyWordProgressStore.swift
//  Kkodle
//
//  Created by 장주진 on 8/8/26.
//

import Foundation

struct DailyWordRecord: Codable, Equatable {
    let epochDay: Int
    let answer: String
    let guesses: [String]
    let won: Bool
}

@Observable
final class DailyWordProgressStore {
    private let defaults: UserDefaults
    private let key = "kkodle.dailyword.record"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func record(for referenceDate: Date = Date()) -> DailyWordRecord? {
        guard let data = defaults.data(forKey: key),
              let record = try? JSONDecoder().decode(DailyWordRecord.self, from: data),
              record.epochDay == Self.epochDay(for: referenceDate) else { return nil }
        return record
    }

    func save(answer: String, guesses: [String], won: Bool, referenceDate: Date = Date()) {
        let record = DailyWordRecord(epochDay: Self.epochDay(for: referenceDate), answer: answer, guesses: guesses, won: won)
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults.set(data, forKey: key)
    }

    private static func epochDay(for date: Date) -> Int {
        Int(date.timeIntervalSince1970 / 86400)
    }
}
