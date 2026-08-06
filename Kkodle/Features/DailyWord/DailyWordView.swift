//
//  DailyWordView.swift
//  Kkodle
//
//  Created by 장주진 on 7/22/26.
//

import SwiftUI

struct DailyWordView: View {
    let heartsStore: HeartsStore
    @State private var viewModel: GameViewModel
    @State private var showResult = true

    init(heartsStore: HeartsStore) {
        self.heartsStore = heartsStore
        let repository = WordRepository(atomCount: 5)
        let answer = repository.todayAnswer() ?? "우산"
        _viewModel = State(initialValue: GameViewModel(answer: answer, validWords: repository.validGuesses))
    }

    var body: some View {
        ZStack {
            VStack {
                GameGridView(viewModel: viewModel)
                Spacer()
                GameKeyboardView(viewModel: viewModel)
            }

            if viewModel.status != .inProgress && showResult {
                GameResultOverlay(status: viewModel.status, answerWord: viewModel.answerWord) {
                    showResult = false
                }
            }
        }
        .onChange(of: viewModel.status) { _, newStatus in
            if newStatus == .won {
                heartsStore.grantCoupon()
            }
        }
        .navigationTitle("오늘의 단어")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DailyWordView(heartsStore: HeartsStore(defaults: UserDefaults(suiteName: "preview.dailyword")!))
}
