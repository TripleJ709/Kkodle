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

    /// Appends to the room's ONE shared guess history at `guessIndex`, then either ends the
    /// game (win/draw) or hands the turn to the opponent.
    ///
    /// This used to run as a `runTransactionBlock` for atomicity, but transaction-committed
    /// writes were found not to reliably wake up other clients' `.observe(.value)` listeners
    /// (confirmed on both simulator and a real device — the submitting client's own listener
    /// could go stale too), leaving the opponent's screen stuck. A plain multi-path update
    /// does trigger listeners reliably. This is a casual 1v1 game between two people taking
    /// turns, so the small race window this trades away (two clients both believing it's their
    /// turn at once) isn't worth the reliability cost — `isMyTurn` is still checked client-side
    /// before this is ever called.
    func submitGuess(code: String, userId: String, opponentId: String, guessIndex: Int, guess: String, isCorrect: Bool) async throws {
        var updates: [String: Any] = [
            "guesses/\(guessIndex)/userId": userId,
            "guesses/\(guessIndex)/word": guess,
        ]
        if isCorrect {
            updates["status"] = BattleRoomState.Status.ended.rawValue
            updates["winnerId"] = userId
        } else if guessIndex + 1 >= BattleRoomState.maxAttempts {
            updates["status"] = BattleRoomState.Status.ended.rawValue
            updates["winnerId"] = NSNull()
        } else {
            updates["currentTurnUserId"] = opponentId
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            roomRef(code).updateChildValues(updates) { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
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
