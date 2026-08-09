//
//  TimeAttackModeView.swift
//  Kkodle
//
//  Created by 장주진 on 8/8/26.
//

import SwiftUI

struct TimeAttackModeView: View {
    let heartsStore: HeartsStore
    @State private var viewModel: TimeAttackGameViewModel
    @Environment(\.dismiss) private var dismiss

    init(heartsStore: HeartsStore) {
        self.heartsStore = heartsStore
        let repository = WordRepository(atomCount: 5)
        _viewModel = State(initialValue: TimeAttackGameViewModel(
            repository: repository,
            heartsStore: heartsStore,
            highScoreStore: TimeAttackHighScoreStore()
        ))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                header

                if viewModel.canExtendTime {
                    Button("하트 써서 +30초") {
                        viewModel.useHeartToExtendTime()
                    }
                    .font(.caption.bold())
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        TimeAttackGridView(viewModel: viewModel.currentRound)
                    }
                    .onChange(of: viewModel.currentRound.attemptsUsed) { _, newValue in
                        withAnimation { proxy.scrollTo(newValue, anchor: .bottom) }
                    }
                }

                Spacer()
                GameKeyboardView(viewModel: viewModel.currentRound)
            }

            if viewModel.runStatus == .ended {
                TimeAttackResultOverlay(
                    wordsSolved: viewModel.wordsSolved,
                    bestScore: viewModel.bestScore,
                    isNewBest: viewModel.isNewBest,
                    onBack: { dismiss() }
                )
            }
        }
        .onChange(of: viewModel.currentRound.status) { _, _ in
            viewModel.handleRoundChange()
        }
        .navigationTitle("시간 제한 모드")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(alignment: .top) {
            HeartsIndicatorView(heartsStore: heartsStore)
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Self.timeText(remaining: viewModel.remainingTime))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(viewModel.remainingTime <= 10 ? Color.red : Color.primary)
                    Text("맞춘 단어 \(viewModel.wordsSolved)개")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .onChange(of: context.date) { _, newDate in
                    viewModel.refreshTimer(referenceDate: newDate)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private static func timeText(remaining: TimeInterval) -> String {
        let total = max(0, Int(remaining.rounded(.up)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

/// Unlike GameGridView, this renders rows one at a time (not a flattened LazyVGrid) so each
/// row can carry a stable id for ScrollViewReader to auto-scroll to as the player keeps guessing
/// past the point where a fixed-height grid would otherwise run off-screen.
private struct TimeAttackGridView: View {
    let viewModel: GameViewModel
    private let cellSize: CGFloat = 60

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(viewModel.gridRows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 8) {
                    ForEach(row) { cell in
                        GameGridCellView(cell: cell, size: cellSize)
                    }
                }
                .id(rowIndex)
            }
        }
        .padding()
    }
}

private struct TimeAttackResultOverlay: View {
    let wordsSolved: Int
    let bestScore: Int
    let isNewBest: Bool
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("시간 종료")
                    .font(.title2.bold())
                Text("맞춘 단어 \(wordsSolved)개")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                if isNewBest {
                    Text("🎉 신기록!")
                        .font(.headline)
                        .foregroundStyle(.pink)
                } else {
                    Text("최고 기록 \(bestScore)개")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Button("돌아가기", action: onBack)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 8)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(40)
        }
    }
}

#Preview {
    TimeAttackModeView(heartsStore: HeartsStore(defaults: UserDefaults(suiteName: "preview.timeattack")!))
}
