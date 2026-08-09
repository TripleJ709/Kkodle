//
//  TimeAttackHighScoreStore.swift
//  Kkodle
//
//  Created by 장주진 on 8/8/26.
//

import Foundation
import Observation

@Observable
final class TimeAttackHighScoreStore {
    private(set) var bestScore: Int

    private let defaults: UserDefaults
    private let storageKey = "kkodle.timeAttack.bestScore"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.bestScore = defaults.integer(forKey: storageKey)
    }

    @discardableResult
    func recordScore(_ score: Int) -> Bool {
        guard score > bestScore else { return false }
        bestScore = score
        defaults.set(bestScore, forKey: storageKey)
        return true
    }
}
