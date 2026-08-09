//
//  BattleRoomService.swift
//  Kkodle
//
//  Created by 장주진 on 8/10/26.
//

import Foundation
import FirebaseDatabase

enum BattleRoomError: LocalizedError {
    case roomNotFound
    case roomFull
    case notYourTurn

    var errorDescription: String? {
        switch self {
        case .roomNotFound: return "존재하지 않는 방이에요."
        case .roomFull: return "이미 인원이 꽉 찬 방이에요."
        case .notYourTurn: return "상대방 차례예요."
        }
    }
}

final class BattleRoomService {
    private let db = Database.database().reference()

    func createRoom(hostId: String, answer: String) throws -> String {
        let code = Self.generateCode()
        let room = BattleRoomState(
            hostId: hostId,
            guestId: nil,
            answer: answer,
            status: .waiting,
            currentTurnUserId: hostId,
            winnerId: nil,
            createdAt: Date().timeIntervalSince1970
        )
        try roomRef(code).setValue(from: room)
        return code
    }

    func joinRoom(code: String, guestId: String) async throws {
        let ref = roomRef(code)
        let snapshot = try await ref.getData()
        guard let room = try? snapshot.data(as: BattleRoomState.self) else {
            throw BattleRoomError.roomNotFound
        }
        guard !room.isFull else {
            throw BattleRoomError.roomFull
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateChildValues(["guestId": guestId, "status": BattleRoomState.Status.playing.rawValue]) { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func observeRoom(code: String, onUpdate: @escaping (BattleRoomState?) -> Void) -> DatabaseHandle {
        let ref = roomRef(code)
        return ref.observe(.value) { snapshot in
            let room = try? snapshot.data(as: BattleRoomState.self)
            onUpdate(room)
        }
    }

    func stopObserving(code: String, handle: DatabaseHandle) {
        roomRef(code).removeObserver(withHandle: handle)
    }

    /// Appends the guess to the current player's list, then either ends the run (win)
    /// or hands the turn to the opponent — all inside one transaction so a race between
    /// both players never corrupts whose turn it is.
    func submitGuess(code: String, userId: String, opponentId: String, guess: String, isCorrect: Bool) async throws {
        let ref = roomRef(code)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.runTransactionBlock({ currentData in
                guard var room = currentData.value as? [String: Any] else {
                    return TransactionResult.success(withValue: currentData)
                }
                guard room["currentTurnUserId"] as? String == userId else {
                    return TransactionResult.abort()
                }
                var guesses = room["guesses"] as? [String: [String: String]] ?? [:]
                var myGuesses = guesses[userId] ?? [:]
                let nextIndex = String(myGuesses.count)
                myGuesses[nextIndex] = guess
                guesses[userId] = myGuesses
                room["guesses"] = guesses

                if isCorrect {
                    room["status"] = BattleRoomState.Status.ended.rawValue
                    room["winnerId"] = userId
                } else {
                    room["currentTurnUserId"] = opponentId
                }

                currentData.value = room
                return TransactionResult.success(withValue: currentData)
            }, andCompletionBlock: { error, committed, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else if !committed {
                    continuation.resume(throwing: BattleRoomError.notYourTurn)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    func leaveRoom(code: String) {
        roomRef(code).removeValue()
    }

    private func roomRef(_ code: String) -> DatabaseReference {
        db.child("rooms").child(code)
    }

    private static func generateCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") // no ambiguous 0/O/1/I
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
