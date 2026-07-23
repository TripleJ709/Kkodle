//
//  HangulJamoExploder.swift
//  Kkodle
//
//  Created by 장주진 on 7/24/26.
//

import Foundation

enum HangulJamoExploder {
    private static let explosionMap: [Character: [Character]] = [
        "ㄲ": ["ㄱ", "ㄱ"],
        "ㄸ": ["ㄷ", "ㄷ"],
        "ㅃ": ["ㅂ", "ㅂ"],
        "ㅆ": ["ㅅ", "ㅅ"],
        "ㅉ": ["ㅈ", "ㅈ"],
        "ㄳ": ["ㄱ", "ㅅ"],
        "ㄵ": ["ㄴ", "ㅈ"],
        "ㄶ": ["ㄴ", "ㅎ"],
        "ㄺ": ["ㄹ", "ㄱ"],
        "ㄻ": ["ㄹ", "ㅁ"],
        "ㄼ": ["ㄹ", "ㅂ"],
        "ㄽ": ["ㄹ", "ㅅ"],
        "ㄾ": ["ㄹ", "ㅌ"],
        "ㄿ": ["ㄹ", "ㅍ"],
        "ㅀ": ["ㄹ", "ㅎ"],
        "ㅄ": ["ㅂ", "ㅅ"],
        "ㅐ": ["ㅏ", "ㅣ"],
        "ㅔ": ["ㅓ", "ㅣ"],
        "ㅘ": ["ㅗ", "ㅏ"],
        "ㅙ": ["ㅗ", "ㅏ", "ㅣ"],
        "ㅚ": ["ㅗ", "ㅣ"],
        "ㅝ": ["ㅜ", "ㅓ"],
        "ㅞ": ["ㅜ", "ㅓ", "ㅣ"],
        "ㅟ": ["ㅜ", "ㅣ"],
        "ㅢ": ["ㅡ", "ㅣ"],
        "ㅒ": ["ㅑ", "ㅣ"],
        "ㅖ": ["ㅕ", "ㅣ"],
    ]

    static func atoms(of jamo: Character?) -> [Character] {
        guard let jamo else { return [] }
        return explosionMap[jamo] ?? [jamo]
    }
}
