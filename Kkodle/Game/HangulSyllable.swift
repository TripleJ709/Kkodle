//
//  HangulSyllable.swift
//  Kkodle
//
//  Created by 장주진 on 7/24/26.
//

import Foundation

struct HangulSyllable: Equatable {
    let choseong: Character
    let jungseong: Character
    let jongseong: Character?

    private static let choseongList: [Character] = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
    private static let jungseongList: [Character] = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
    private static let jongseongList: [Character?] = {
        let batchims: [Character] = Array("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")
        return [nil] + batchims.map { (character: Character) -> Character? in character }
    }()

    private static let hangulSyllableRange: ClosedRange<UInt32> = 0xAC00...0xD7A3
    private static let jungseongCount = 21
    private static let jongseongCount = 28

    init?(_ character: Character) {
        guard character.unicodeScalars.count == 1,
              let scalar = character.unicodeScalars.first,
              HangulSyllable.hangulSyllableRange.contains(scalar.value) else { return nil }

        let offset = Int(scalar.value - HangulSyllable.hangulSyllableRange.lowerBound)
        let choseongIndex = offset / (HangulSyllable.jungseongCount * HangulSyllable.jongseongCount)
        let jungseongIndex = (offset % (HangulSyllable.jungseongCount * HangulSyllable.jongseongCount)) / HangulSyllable.jongseongCount
        let jongseongIndex = offset % HangulSyllable.jongseongCount

        choseong = HangulSyllable.choseongList[choseongIndex]
        jungseong = HangulSyllable.jungseongList[jungseongIndex]
        jongseong = HangulSyllable.jongseongList[jongseongIndex]
    }

    static func compose(choseong: Character, jungseong: Character, jongseong: Character?) -> Character? {
        guard let choseongIndex = choseongList.firstIndex(of: choseong),
              let jungseongIndex = jungseongList.firstIndex(of: jungseong),
              let jongseongIndex = jongseongList.firstIndex(of: jongseong) else { return nil }

        let offset = (choseongIndex * jungseongCount + jungseongIndex) * jongseongCount + jongseongIndex
        guard let scalar = Unicode.Scalar(hangulSyllableRange.lowerBound + UInt32(offset)) else { return nil }
        return Character(scalar)
    }
}
