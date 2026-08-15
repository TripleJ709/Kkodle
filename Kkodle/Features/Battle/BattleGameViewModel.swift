//
//  BattleGameViewModel.swift
//  Kkodle
//
//  Created by 장주진 on 8/10/26.
//

import Foundation
import FirebaseDatabase
import Observation

@Observable
final class BattleGameViewModel {
    private let service: BattleRoomService
    let code: String
    let myUserId: String
    private let validWords: Set<String>

    private(set) var room: BattleRoomState?
    private(set) var currentGuess: [Character] = []
    private(set) var errorMessage: String?
    private(set) var isSubmitting = false
    private(set) var remainingTurnSeconds: Int = Int(BattleRoomState.turnDuration)

    private var observerHandle: DatabaseHandle?
    /// Guards against re-firing the timeout pass every tick while waiting for
    /// the server write we already sent to come back through the listener.
    private var timeoutHandledForDeadline: Double?
    /// Tracks which room status we last armed an onDisconnect handler for, so
    /// we only re-register it on an actual transition (waiting → playing →
    /// ended), not on every listener update.
    private var disconnectHandlerArmedFor: BattleRoomState.Status?

    init(service: BattleRoomService, code: String, myUserId: String, validWords: Set<String>) {
        self.service = service
        self.code = code
        self.myUserId = myUserId
        self.validWords = validWords
    }

    func startObserving() {
        guard observerHandle == nil else { return }
        observerHandle = service.observeRoom(code: code) { [weak self] newRoom in
            guard let self else { return }
            // Once we've seen a real room, ignore spurious nil snapshots rather than
            // treating a possibly-transient listener hiccup as "the room was deleted" —
            // a genuine deletion only ever happens via an explicit leaveRoom() call.
            if newRoom != nil || self.room == nil {
                self.room = newRoom
            }
            self.refreshTurnTimer()
            if let newRoom {
                self.syncDisconnectHandler(for: newRoom)
            }
        }
    }

    func stopObserving() {
        if let handle = observerHandle {
            service.stopObserving(code: code, handle: handle)
            observerHandle = nil
        }
    }

    func leaveRoom() {
        service.cancelDisconnectHandler(code: code)
        stopObserving()
        service.leaveRoom(code: code)
    }

    /// Keeps a server-side onDisconnect handler in sync with what should
    /// happen if *this* client vanishes right now: clean up an abandoned
    /// waiting room, forfeit an in-progress match to the opponent, or do
    /// nothing once the match already ended normally. See
    /// `BattleRoomService`'s onDisconnect methods for why re-registering
    /// replaces rather than stacks.
    private func syncDisconnectHandler(for room: BattleRoomState) {
        guard disconnectHandlerArmedFor != room.status else { return }
        switch room.status {
        case .waiting:
            service.armRoomCleanupOnDisconnect(code: code)
        case .playing:
            guard let opponentId = room.opponentId(of: myUserId) else { return }
            service.armForfeitOnDisconnect(code: code, forfeitToOpponentId: opponentId)
        case .ended:
            service.cancelDisconnectHandler(code: code)
        }
        disconnectHandlerArmedFor = room.status
    }

    func clearError() {
        errorMessage = nil
    }

    /// Recomputes the turn countdown from the server-synced deadline, and —
    /// if it's the *opponent's* turn that ran out — reports the timeout so
    /// the turn passes to me. Only the waiting player does this (not the
    /// active one) so a backgrounded/stuck opponent's turn still gets
    /// reclaimed instead of stalling the game.
    func refreshTurnTimer(referenceDate: Date = Date()) {
        guard let room, room.status == .playing, let deadline = room.turnDeadline else {
            remainingTurnSeconds = Int(BattleRoomState.turnDuration)
            return
        }
        let remaining = deadline - referenceDate.timeIntervalSince1970
        remainingTurnSeconds = max(0, Int(remaining.rounded(.up)))

        // Small grace window past zero to absorb clock drift/latency against a
        // submission that's already in flight from the active player's side.
        guard remaining <= -1, !isMyTurn, let opponentId, timeoutHandledForDeadline != deadline else { return }
        timeoutHandledForDeadline = deadline
        Task {
            try? await service.passTurnOnTimeout(code: code, newActiveUserId: myUserId)
        }
    }

    var isMyTurn: Bool { room?.currentTurnUserId == myUserId }
    var opponentId: String? { room.flatMap { $0.opponentId(of: myUserId) } }
    var isOpponentPresent: Bool { room?.isFull ?? false }

    private var answerAtoms: [Character] {
        guard let answer = room?.answer else { return [] }
        return HangulAtomizer.atomize(answer) ?? []
    }

    var atomCount: Int { max(answerAtoms.count, 1) }

    var bestHints: [Character: LetterHint] {
        var result: [Character: LetterHint] = [:]
        for guess in gridRows.flatMap({ $0 }) where guess.hint != nil {
            guard let atom = guess.atom, let hint = guess.hint else { continue }
            if let existing = result[atom] {
                if rank(hint) > rank(existing) { result[atom] = hint }
            } else {
                result[atom] = hint
            }
        }
        return result
    }

    var gridRows: [[GridCell]] {
        guard let room else { return [] }
        let atoms = answerAtoms
        let entries = room.orderedGuesses
        return (0..<BattleRoomState.maxAttempts).map { rowIndex in
            if rowIndex < entries.count {
                let entry = entries[rowIndex]
                guard let guessAtoms = HangulAtomizer.atomize(entry.word),
                      let hints = try? WordComparer.compare(guess: guessAtoms, answer: atoms) else {
                    return (0..<atoms.count).map { _ in GridCell(atom: nil, hint: nil) }
                }
                return zip(guessAtoms, hints).map { GridCell(atom: $0, hint: $1) }
            } else if rowIndex == entries.count && isMyTurn {
                return (0..<atoms.count).map { columnIndex in
                    columnIndex < currentGuess.count
                        ? GridCell(atom: currentGuess[columnIndex], hint: nil)
                        : GridCell(atom: nil, hint: nil)
                }
            } else {
                return (0..<atoms.count).map { _ in GridCell(atom: nil, hint: nil) }
            }
        }
    }

    func inputAtom(_ atom: Character) {
        guard isMyTurn, room?.status == .playing, currentGuess.count < atomCount else { return }
        currentGuess.append(atom)
    }

    func deleteLastAtom() {
        guard isMyTurn, !currentGuess.isEmpty else { return }
        currentGuess.removeLast()
    }

    func submitGuess() async {
        guard isMyTurn, currentGuess.count == atomCount, let opponentId, var currentRoom = room,
              currentRoom.status == .playing else { return }
        let word = HangulComposer.compose(currentGuess)
        guard validWords.contains(word) else {
            errorMessage = "사전에 없는 단어예요."
            return
        }
        let guessIndex = currentRoom.orderedGuesses.count
        let isCorrect = word == currentRoom.answer
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.submitGuess(
                code: code, userId: myUserId, opponentId: opponentId,
                guessIndex: guessIndex, guess: word, isCorrect: isCorrect
            )
            currentGuess = []
            // Reflect our own submission locally right away, rather than waiting on our
            // own listener to echo back a write we already know succeeded — see the note
            // on BattleRoomService.submitGuess about listener reliability after a write.
            currentRoom.guesses.append(BattleGuessEntry(userId: myUserId, word: word))
            if isCorrect {
                currentRoom.status = .ended
                currentRoom.winnerId = myUserId
            } else if guessIndex + 1 >= BattleRoomState.maxAttempts {
                currentRoom.status = .ended
                currentRoom.winnerId = nil
            } else {
                currentRoom.currentTurnUserId = opponentId
                currentRoom.turnDeadline = Date().timeIntervalSince1970 + BattleRoomState.turnDuration
            }
            room = currentRoom
        } catch {
            errorMessage = error.localizedDescription
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
