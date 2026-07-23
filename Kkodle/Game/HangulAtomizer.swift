//
//  HangulAtomizer.swift
//  Kkodle
//
//  Created by 장주진 on 7/24/26.
//

import Foundation

enum HangulAtomizer {
    static func atomize(_ word: String) -> [Character]? {
        var atoms: [Character] = []
        for character in word {
            guard let syllable = HangulSyllable(character) else { return nil }
            atoms.append(contentsOf: HangulJamoExploder.atoms(of: syllable.choseong))
            atoms.append(contentsOf: HangulJamoExploder.atoms(of: syllable.jungseong))
            atoms.append(contentsOf: HangulJamoExploder.atoms(of: syllable.jongseong))
        }
        return atoms
    }
}
