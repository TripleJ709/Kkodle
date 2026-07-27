//
//  GameViewModel.swift
//  Kkodle
//
//  Created by 장주진 on 7/24/26.
//

import Foundation
import Observation

enum GameStatus: Equatable {
    case inProgress
    case won
    case lost
}

enum SubmitError: Error {
    case incompleteGuess
    case invalidWord
}

struct GuessResult: Identifiable, Equatable {
    let id = UUID()
    let atoms: [Character]
    let hints: [LetterHint]
}

struct GridCell: Identifiable {
    let id = UUID()
    let atom: Character?
    let hint: LetterHint?
}

@Observable
final class GameViewModel {
    private(set) var maxAttempts: Int

    private(set) var currentGuess: [Character] = []
    private(set) var submittedGuesses: [GuessResult] = []
    private(set) var status: GameStatus = .inProgress

    let answerWord: String

    private let answerAtoms: [Character]
    private let validWords: Set<String>

    init(answer: String, validWords: Set<String>, maxAttempts: Int = 6) {
        self.answerWord = answer
        self.answerAtoms = HangulAtomizer.atomize(answer) ?? []
        self.validWords = validWords
        self.maxAttempts = maxAttempts
    }

    var atomCount: Int { answerAtoms.count }
    var attemptsUsed: Int { submittedGuesses.count }

    var bestHints: [Character: LetterHint] {
        var result: [Character: LetterHint] = [:]
        for guess in submittedGuesses {
            for (atom, hint) in zip(guess.atoms, guess.hints) {
                if rank(hint) > rank(result[atom] ?? .absent) {
                    result[atom] = hint
                }
            }
        }
        return result
    }

    var gridRows: [[GridCell]] {
        (0..<maxAttempts).map { rowIndex in
            if rowIndex < submittedGuesses.count {
                let guess = submittedGuesses[rowIndex]
                return zip(guess.atoms, guess.hints).map { GridCell(atom: $0, hint: $1) }
            } else if rowIndex == submittedGuesses.count {
                return (0..<atomCount).map { columnIndex in
                    columnIndex < currentGuess.count
                        ? GridCell(atom: currentGuess[columnIndex], hint: nil)
                        : GridCell(atom: nil, hint: nil)
                }
            } else {
                return (0..<atomCount).map { _ in GridCell(atom: nil, hint: nil) }
            }
        }
    }

    func inputAtom(_ atom: Character) {
        guard status == .inProgress, currentGuess.count < atomCount else { return }
        currentGuess.append(atom)
    }

    func deleteLastAtom() {
        guard status == .inProgress, !currentGuess.isEmpty else { return }
        currentGuess.removeLast()
    }

    func extendAttempt() {
        guard status == .lost else { return }
        maxAttempts += 1
        status = .inProgress
    }

    func submitGuess() throws {
        guard status == .inProgress else { return }
        guard currentGuess.count == atomCount else {
            throw SubmitError.incompleteGuess
        }

        let composedWord = HangulComposer.compose(currentGuess)
        guard validWords.contains(composedWord) else {
            throw SubmitError.invalidWord
        }

        let hints = try WordComparer.compare(guess: currentGuess, answer: answerAtoms)
        submittedGuesses.append(GuessResult(atoms: currentGuess, hints: hints))
        currentGuess = []

        if hints.allSatisfy({ $0 == .correct }) {
            status = .won
        } else if submittedGuesses.count >= maxAttempts {
            status = .lost
        }
    }

    private func rank(_ hint: LetterHint) -> Int {
        switch hint {
        case .absent: return 0
        case .present: return 1
        case .correct: return 2
        }
    }
}
