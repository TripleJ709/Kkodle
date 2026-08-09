//
//  TimeAttackGameViewModel.swift
//  Kkodle
//
//  Created by 장주진 on 8/8/26.
//

import Foundation
import Observation

enum TimeAttackRunStatus: Equatable {
    case playing
    case ended
}

@Observable
final class TimeAttackGameViewModel {
    /// Effectively unlimited within a 3-minute run — no realistic amount of guessing reaches this.
    static let wordAttemptCap = 200
    static let runDuration: TimeInterval = 3 * 60
    static let heartTimeBonus: TimeInterval = 30

    private(set) var currentRound: GameViewModel
    private(set) var wordsSolved = 0
    private(set) var runStatus: TimeAttackRunStatus = .playing
    private(set) var remainingTime: TimeInterval = TimeAttackGameViewModel.runDuration
    private(set) var isNewBest = false

    private let repository: WordRepository
    private let heartsStore: HeartsStore
    private let highScoreStore: TimeAttackHighScoreStore
    private var previousAnswer: String?
    private var runEndDate: Date

    init(repository: WordRepository, heartsStore: HeartsStore, highScoreStore: TimeAttackHighScoreStore) {
        self.repository = repository
        self.heartsStore = heartsStore
        self.highScoreStore = highScoreStore
        let answer = repository.randomAnswer() ?? "우산"
        self.previousAnswer = answer
        self.currentRound = GameViewModel(answer: answer, validWords: repository.validGuesses, maxAttempts: Self.wordAttemptCap)
        self.runEndDate = Date().addingTimeInterval(Self.runDuration)
    }

    var bestScore: Int { highScoreStore.bestScore }

    /// Hearts aren't tied to a specific mistake here (guesses per word are effectively unlimited) —
    /// they can be spent any time during the run to buy more time on the clock.
    var canExtendTime: Bool { runStatus == .playing && heartsStore.hasHearts }

    func useHeartToExtendTime() {
        guard canExtendTime else { return }
        heartsStore.consumeHeart()
        runEndDate = runEndDate.addingTimeInterval(Self.heartTimeBonus)
        refreshTimer()
    }

    func handleRoundChange() {
        switch currentRound.status {
        case .won:
            wordsSolved += 1
            startNextRound()
        case .lost:
            // Astronomically unlikely at wordAttemptCap guesses, but don't get stuck if it happens.
            startNextRound()
        case .inProgress:
            break
        }
    }

    func refreshTimer(referenceDate: Date = Date()) {
        guard runStatus == .playing else { return }
        remainingTime = max(0, runEndDate.timeIntervalSince(referenceDate))
        if remainingTime <= 0 {
            endRun()
        }
    }

    private func endRun() {
        runStatus = .ended
        isNewBest = highScoreStore.recordScore(wordsSolved)
    }

    private func startNextRound() {
        let answer = repository.randomAnswer(excluding: previousAnswer) ?? "우산"
        previousAnswer = answer
        currentRound = GameViewModel(answer: answer, validWords: repository.validGuesses, maxAttempts: Self.wordAttemptCap)
    }
}
