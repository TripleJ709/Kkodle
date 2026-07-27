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
    private(set) var wordsSolved = 0
    private(set) var lastRoundPoints = 0
    private(set) var isNewBest = false
    private(set) var runStatus: EndlessRunStatus = .playing

    private let repository: WordRepository
    private let heartsStore: HeartsStore
    private let highScoreStore: EndlessHighScoreStore
    private var previousAnswer: String?

    init(repository: WordRepository, heartsStore: HeartsStore, highScoreStore: EndlessHighScoreStore) {
        self.repository = repository
        self.heartsStore = heartsStore
        self.highScoreStore = highScoreStore
        let answer = repository.randomAnswer() ?? "우산"
        self.previousAnswer = answer
        self.currentRound = GameViewModel(answer: answer, validWords: repository.validGuesses, maxAttempts: Self.baseAttempts)
    }

    var hearts: Int { heartsStore.hearts }
    var bestScore: Int { highScoreStore.bestScore }

    var canUseHeartToContinue: Bool {
        currentRound.status == .lost && heartsStore.hasHearts
    }

    func handleRoundChange() {
        switch currentRound.status {
        case .won:
            let points = pointsForCurrentRound()
            lastRoundPoints = points
            score += points
            wordsSolved += 1
        case .lost:
            if !heartsStore.hasHearts {
                endRun()
            }
        case .inProgress:
            break
        }
    }

    func advanceToNextRound() {
        guard currentRound.status == .won else { return }
        startNextRound()
    }

    func useHeartToContinue() {
        guard canUseHeartToContinue else { return }
        heartsStore.consumeHeart()
        currentRound.extendAttempt()
    }

    func giveUp() {
        guard currentRound.status == .lost else { return }
        endRun()
    }

    private func endRun() {
        runStatus = .ended
        isNewBest = highScoreStore.recordScore(score)
    }

    private func pointsForCurrentRound() -> Int {
        max(1, 6 - currentRound.attemptsUsed)
    }

    private func startNextRound() {
        let answer = repository.randomAnswer(excluding: previousAnswer) ?? "우산"
        previousAnswer = answer
        currentRound = GameViewModel(answer: answer, validWords: repository.validGuesses, maxAttempts: Self.baseAttempts)
    }
}
