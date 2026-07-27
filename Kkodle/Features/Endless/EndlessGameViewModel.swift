//
//  EndlessGameViewModel.swift
//  Kkodle
//
//  Created by 장주진 on 7/26/26.
//

import Foundation
import Observation

enum EndlessRunStatus: Equatable {
    case playing
    case ended
}

@Observable
final class EndlessGameViewModel {
    static let baseAttempts = 5

    private(set) var currentRound: GameViewModel
    private(set) var score = 0
    private(set) var runStatus: EndlessRunStatus = .playing

    private let repository: WordRepository
    private let heartsStore: HeartsStore
    private var previousAnswer: String?

    init(repository: WordRepository, heartsStore: HeartsStore) {
        self.repository = repository
        self.heartsStore = heartsStore
        let answer = repository.randomAnswer() ?? "우산"
        self.previousAnswer = answer
        self.currentRound = GameViewModel(answer: answer, validWords: repository.validGuesses, maxAttempts: Self.baseAttempts)
    }

    var hearts: Int { heartsStore.hearts }

    var canUseHeartToContinue: Bool {
        currentRound.status == .lost && heartsStore.hasHearts
    }

    func handleRoundChange() {
        switch currentRound.status {
        case .won:
            score += 1
            startNextRound()
        case .lost:
            if !heartsStore.hasHearts {
                runStatus = .ended
            }
        case .inProgress:
            break
        }
    }

    func useHeartToContinue() {
        guard canUseHeartToContinue else { return }
        heartsStore.consumeHeart()
        currentRound.extendAttempt()
    }

    func giveUp() {
        guard currentRound.status == .lost else { return }
        runStatus = .ended
    }

    private func startNextRound() {
        let answer = repository.randomAnswer(excluding: previousAnswer) ?? "우산"
        previousAnswer = answer
        currentRound = GameViewModel(answer: answer, validWords: repository.validGuesses, maxAttempts: Self.baseAttempts)
    }
}
