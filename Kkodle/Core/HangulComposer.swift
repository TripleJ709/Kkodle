//
//  HangulComposer.swift
//  Kkodle
//
//  Original Source:
//  https://github.com/Kim-Junhwan/IOS-CustomKeyboard/blob/main/CustomKeyboard/Automata/HangulAutomata.swift
//  (state-machine transitions and Unicode composition math adapted from this reference)
//
//  Created by 장주진 on 7/24/26.
//

import Foundation

enum HangulComposer {
    private static let baseVowels: Set<Character> = ["ㅏ", "ㅑ", "ㅓ", "ㅕ", "ㅗ", "ㅛ", "ㅜ", "ㅠ", "ㅡ", "ㅣ"]

    private static let consonantDoubling: [Character: Character] = [
        "ㄱ": "ㄲ", "ㄷ": "ㄸ", "ㅂ": "ㅃ", "ㅅ": "ㅆ", "ㅈ": "ㅉ",
    ]

    private static let compoundVowelPairs: [Character: [Character: Character]] = [
        "ㅏ": ["ㅣ": "ㅐ"],
        "ㅓ": ["ㅣ": "ㅔ"],
        "ㅑ": ["ㅣ": "ㅒ"],
        "ㅕ": ["ㅣ": "ㅖ"],
        "ㅗ": ["ㅏ": "ㅘ", "ㅣ": "ㅚ"],
        "ㅘ": ["ㅣ": "ㅙ"],
        "ㅜ": ["ㅓ": "ㅝ", "ㅣ": "ㅟ"],
        "ㅝ": ["ㅣ": "ㅞ"],
        "ㅡ": ["ㅣ": "ㅢ"],
    ]

    private static let compoundJongseongPairs: [Character: [Character: Character]] = [
        "ㄱ": ["ㅅ": "ㄳ"],
        "ㄴ": ["ㅈ": "ㄵ", "ㅎ": "ㄶ"],
        "ㄹ": ["ㄱ": "ㄺ", "ㅁ": "ㄻ", "ㅂ": "ㄼ", "ㅅ": "ㄽ", "ㅌ": "ㄾ", "ㅍ": "ㄿ", "ㅎ": "ㅀ"],
        "ㅂ": ["ㅅ": "ㅄ"],
    ]

    private static let jongseongSplit: [Character: (Character, Character)] = {
        var result: [Character: (Character, Character)] = [:]
        for (first, seconds) in compoundJongseongPairs {
            for (second, combined) in seconds {
                result[combined] = (first, second)
            }
        }
        for (base, doubled) in consonantDoubling {
            result[doubled] = (base, base)
        }
        return result
    }()

    static func compose(_ atoms: [Character]) -> String {
        var syllables: [Character] = []
        var choseong: Character?
        var jungseong: Character?
        var jongseong: Character?

        func flush() {
            defer { choseong = nil; jungseong = nil; jongseong = nil }
            guard let choseong, let jungseong else {
                if let choseong { syllables.append(choseong) }
                return
            }
            syllables.append(HangulSyllable.compose(choseong: choseong, jungseong: jungseong, jongseong: jongseong) ?? choseong)
        }

        for atom in atoms {
            if baseVowels.contains(atom) {
                if choseong == nil {
                    flush()
                    jungseong = atom
                } else if jungseong == nil {
                    jungseong = atom
                } else if jongseong == nil, let merged = compoundVowelPairs[jungseong!]?[atom] {
                    jungseong = merged
                } else if let carried = jongseong {
                    if let (kept, given) = jongseongSplit[carried] {
                        jongseong = kept
                        flush()
                        choseong = given
                    } else {
                        jongseong = nil
                        flush()
                        choseong = carried
                    }
                    jungseong = atom
                } else {
                    flush()
                    jungseong = atom
                }
            } else {
                if choseong == nil {
                    choseong = atom
                } else if jungseong == nil {
                    if choseong == atom, let doubled = consonantDoubling[atom] {
                        choseong = doubled
                    } else {
                        flush()
                        choseong = atom
                    }
                } else if jongseong == nil {
                    jongseong = atom
                } else if let merged = compoundJongseongPairs[jongseong!]?[atom] {
                    jongseong = merged
                } else if jongseong == atom, let doubled = consonantDoubling[atom] {
                    jongseong = doubled
                } else {
                    flush()
                    choseong = atom
                }
            }
        }
        flush()

        return String(syllables)
    }
}
