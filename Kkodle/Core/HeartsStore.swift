//
//  HeartsStore.swift
//  Kkodle
//
//  Created by 장주진 on 7/25/26.
//

import Foundation
import Observation

@Observable
final class HeartsStore {
    static let maxHearts = 3

    private(set) var hearts: Int

    private let defaults: UserDefaults
    private let storageKey = "kkodle.hearts.count"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.object(forKey: storageKey) as? Int {
            self.hearts = stored
        } else {
            self.hearts = Self.maxHearts
        }
    }

    var hasHearts: Bool { hearts > 0 }

    func consumeHeart() {
        guard hearts > 0 else { return }
        hearts -= 1
        persist()
    }

    func refillHeart() {
        guard hearts < Self.maxHearts else { return }
        hearts += 1
        persist()
    }

    private func persist() {
        defaults.set(hearts, forKey: storageKey)
    }
}
