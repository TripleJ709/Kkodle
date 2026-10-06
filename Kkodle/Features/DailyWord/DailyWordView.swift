//
//  DailyWordView.swift
//  Kkodle
//
//  Created by 장주진 on 7/22/26.
//

import SwiftUI

struct DailyWordView: View {
    let heartsStore: HeartsStore
    let progressStore: DailyWordProgressStore
    @State private var viewModel: GameViewModel
    @State private var showResult = true
    /// 이번 플레이에서 보상을 받았는지 여부. 이미 끝난 기록을 복원한 경우에는 false라서
    /// 재입장할 때마다 "획득" 문구가 다시 뜨지 않습니다.
    @State private var earnedReward = false

    init(heartsStore: HeartsStore, progressStore: DailyWordProgressStore = DailyWordProgressStore()) {
        self.heartsStore = heartsStore
        self.progressStore = progressStore
        let repository = WordRepository(atomCount: 5)
        let answer = repository.todayAnswer() ?? "우산"

        if let record = progressStore.record(), record.answer == answer {
            _viewModel = State(initialValue: GameViewModel(
                answer: answer,
                validWords: repository.validGuesses,
                restoringGuesses: record.guesses,
                status: record.won ? .won : .lost
            ))
        } else {
            _viewModel = State(initialValue: GameViewModel(answer: answer, validWords: repository.validGuesses))
        }
    }

    var body: some View {
        ZStack {
            VStack {
                GameGridView(viewModel: viewModel)
                Spacer()
                GameKeyboardView(viewModel: viewModel)
            }

            if viewModel.status != .inProgress && showResult {
                GameResultOverlay(
                    status: viewModel.status,
                    answerWord: viewModel.answerWord,
                    rewardText: earnedReward ? "하트 추가권 +1 획득!" : nil
                ) {
                    showResult = false
                }
            }
        }
        .background(KkodleTheme.background.ignoresSafeArea())
        .onChange(of: viewModel.status) { _, newStatus in
            guard newStatus != .inProgress else { return }
            if newStatus == .won {
                heartsStore.grantCoupon()
                earnedReward = true
            }
            let guessWords = viewModel.submittedGuesses.map { HangulComposer.compose($0.atoms) }
            progressStore.save(answer: viewModel.answerWord, guesses: guessWords, won: newStatus == .won)
        }
        .navigationTitle("오늘의 단어")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DailyWordView(heartsStore: HeartsStore(defaults: UserDefaults(suiteName: "preview.dailyword")!))
}
