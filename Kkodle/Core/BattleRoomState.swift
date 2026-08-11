//
//  BattleRoomState.swift
//  Kkodle
//
//  Created by 장주진 on 8/10/26.
//

import Foundation

struct BattleGuessEntry: Codable, Equatable {
    var userId: String
    var word: String
}

struct BattleRoomState: Codable, Equatable {
    enum Status: String, Codable {
        case waiting
        case playing
        case ended
    }

    static let maxAttempts = 6

    var hostId: String
    var guestId: String?
    var answer: String
    var status: Status
    var currentTurnUserId: String?
    var winnerId: String?
    var createdAt: Double
    /// One shared guess history both players contribute to in turn order —
    /// this is a battle over a single board, not two separate ones.
    /// Written at integer paths ("guesses/0", "guesses/1", ...); Realtime
    /// Database serializes an object whose keys are all sequential integers
    /// as a JSON array on read (not as an object), so this must be modeled
    /// as a native Swift array to match the wire shape — a
    /// `[String: BattleGuessEntry]` dictionary fails to decode with a
    /// typeMismatch against that array.
    var guesses: [BattleGuessEntry]

    init(
        hostId: String,
        guestId: String?,
        answer: String,
        status: Status,
        currentTurnUserId: String?,
        winnerId: String?,
        createdAt: Double,
        guesses: [BattleGuessEntry] = []
    ) {
        self.hostId = hostId
        self.guestId = guestId
        self.answer = answer
        self.status = status
        self.currentTurnUserId = currentTurnUserId
        self.winnerId = winnerId
        self.createdAt = createdAt
        self.guesses = guesses
    }

    private enum CodingKeys: String, CodingKey {
        case hostId, guestId, answer, status, currentTurnUserId, winnerId, createdAt, guesses
    }

    // Realtime Database omits keys whose value is an empty object (there's no
    // "empty object" in its data model), so a room with zero guesses so far
    // arrives with the `guesses` key missing entirely rather than `{}`. Decode
    // it defensively instead of relying on the synthesized decoder, which would
    // otherwise throw `keyNotFound` for a perfectly normal, guess-less room.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hostId = try container.decode(String.self, forKey: .hostId)
        guestId = try container.decodeIfPresent(String.self, forKey: .guestId)
        answer = try container.decode(String.self, forKey: .answer)
        status = try container.decode(Status.self, forKey: .status)
        currentTurnUserId = try container.decodeIfPresent(String.self, forKey: .currentTurnUserId)
        winnerId = try container.decodeIfPresent(String.self, forKey: .winnerId)
        createdAt = try container.decode(Double.self, forKey: .createdAt)
        guesses = try container.decodeIfPresent([BattleGuessEntry].self, forKey: .guesses) ?? []
    }

    var isFull: Bool { guestId != nil }

    var orderedGuesses: [BattleGuessEntry] { guesses }

    func opponentId(of userId: String) -> String? {
        userId == hostId ? guestId : hostId
    }
}
