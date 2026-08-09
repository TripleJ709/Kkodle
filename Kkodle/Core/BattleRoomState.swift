//
//  BattleRoomState.swift
//  Kkodle
//
//  Created by 장주진 on 8/10/26.
//

import Foundation

struct BattleRoomState: Codable, Equatable {
    enum Status: String, Codable {
        case waiting
        case playing
        case ended
    }

    var hostId: String
    var guestId: String?
    var answer: String
    var status: Status
    var currentTurnUserId: String?
    var winnerId: String?
    var createdAt: Double
    /// userId -> (guess index as string) -> composed guess word.
    /// A dictionary keyed by string index (rather than a native array) avoids
    /// Realtime Database's array/object ambiguity and race conditions on append.
    var guesses: [String: [String: String]] = [:]

    var isFull: Bool { guestId != nil }

    func guessList(for userId: String) -> [String] {
        guard let dict = guesses[userId] else { return [] }
        return dict.keys.sorted { (Int($0) ?? 0) < (Int($1) ?? 0) }.compactMap { dict[$0] }
    }

    func opponentId(of userId: String) -> String? {
        userId == hostId ? guestId : hostId
    }
}
