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
    static let regenInterval: TimeInterval = 30 * 60

    private(set) var hearts: Int
    private(set) var pendingCoupons: Int

    private let defaults: UserDefaults
    private let heartsKey = "kkodle.hearts.count"
    private let lastRegenKey = "kkodle.hearts.lastRegenAt"
    private let couponsKey = "kkodle.hearts.pendingCoupons"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.object(forKey: heartsKey) as? Int {
            self.hearts = stored
        } else {
            self.hearts = Self.maxHearts
        }
        self.pendingCoupons = defaults.integer(forKey: couponsKey)
        // Migration: hearts lost before regen tracking existed have no anchor recorded.
        // Start the clock now rather than leaving them stuck with no ETA forever.
        if hearts < Self.maxHearts && lastRegenAnchor == nil {
            lastRegenAnchor = Date()
        }
        refresh()
    }

    var hasHearts: Bool { hearts > 0 }

    /// The moment the next heart will be ready, or nil if already at max (nothing to wait for).
    var nextHeartETA: Date? {
        guard hearts < Self.maxHearts, let anchor = lastRegenAnchor else { return nil }
        return anchor.addingTimeInterval(Self.regenInterval)
    }

    func consumeHeart() {
        guard hearts > 0 else { return }
        hearts -= 1
        if lastRegenAnchor == nil {
            lastRegenAnchor = Date()
        }
        persist()
    }

    /// Banks a reward coupon (e.g. from completing the daily word). Never lost even if hearts
    /// are already full — it just waits until the player chooses to redeem it.
    func grantCoupon() {
        pendingCoupons += 1
        persist()
    }

    /// Manually converts one banked coupon into a heart, up to the max. This is deliberately
    /// NOT automatic and only intended to be offered outside of an active run (e.g. the home
    /// screen), so hoarded coupons can never turn into more than `maxHearts` continues in a
    /// single endless-mode run.
    @discardableResult
    func redeemCoupon() -> Bool {
        guard pendingCoupons > 0, hearts < Self.maxHearts else { return false }
        pendingCoupons -= 1
        hearts += 1
        if hearts >= Self.maxHearts {
            lastRegenAnchor = nil
        }
        persist()
        return true
    }

    /// Recomputes how many hearts should have regenerated since the last time we counted,
    /// based on real elapsed time rather than any timer that would need the app to stay running.
    func refresh(referenceDate: Date = Date()) {
        guard hearts < Self.maxHearts, let anchor = lastRegenAnchor else { return }
        let elapsed = referenceDate.timeIntervalSince(anchor)
        guard elapsed >= Self.regenInterval else { return }

        let heartsToAdd = Int(elapsed / Self.regenInterval)
        hearts = min(Self.maxHearts, hearts + heartsToAdd)

        if hearts >= Self.maxHearts {
            lastRegenAnchor = nil
        } else {
            lastRegenAnchor = anchor.addingTimeInterval(Double(heartsToAdd) * Self.regenInterval)
        }
        persist()
    }

    private var lastRegenAnchor: Date? {
        get { defaults.object(forKey: lastRegenKey) as? Date }
        set { defaults.set(newValue, forKey: lastRegenKey) }
    }

    private func persist() {
        defaults.set(hearts, forKey: heartsKey)
        defaults.set(pendingCoupons, forKey: couponsKey)
    }
}
