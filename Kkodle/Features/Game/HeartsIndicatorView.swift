//
//  HeartsIndicatorView.swift
//  Kkodle
//
//  Created by 장주진 on 7/25/26.
//

import SwiftUI

struct HeartsIndicatorView: View {
    let heartsStore: HeartsStore

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                ForEach(0..<HeartsStore.maxHearts, id: \.self) { index in
                    Image(systemName: index < heartsStore.hearts ? "heart.fill" : "heart")
                        .foregroundStyle(index < heartsStore.hearts ? Color.red : Color.secondary.opacity(0.4))
                        .font(.system(size: 20))
                }
            }

            if let eta = heartsStore.nextHeartETA {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text("다음 하트까지 \(Self.countdownText(until: eta, now: context.date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .onChange(of: context.date) { _, newDate in
                            heartsStore.refresh(referenceDate: newDate)
                        }
                }
            }
        }
    }

    private static func countdownText(until eta: Date, now: Date) -> String {
        let remaining = max(0, Int(eta.timeIntervalSince(now)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    HeartsIndicatorView(heartsStore: HeartsStore(defaults: UserDefaults(suiteName: "preview.hearts")!))
}
