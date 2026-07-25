//
//  ContentView.swift
//  Kkodle
//
//  Created by 장주진 on 7/22/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: GameViewModel
    @State private var showResult = true

    init() {
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
    }
}

#Preview {
    ContentView()
}
