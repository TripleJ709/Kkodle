//
//  GameHelpView.swift
//  Kkodle
//
//  Created by 장주진 on 8/16/26.
//

import SwiftUI

/// Explains the core hint mechanic (jamo-level, not syllable-level color
/// hints) that every mode shares — separate from each mode's own "?" info,
/// which only covers that mode's specific rules.
struct GameHelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let legendCellSize: CGFloat = 48

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("6번의 기회 안에 5글자 한국어 단어를 맞혀보세요. 음절이 아니라 자음/모음 하나하나 단위로 힌트가 나와요.")
                        .font(.body)

                    VStack(alignment: .leading, spacing: 16) {
                        legendRow(atom: "ㄱ", hint: .correct, title: "정확해요", detail: "이 자음/모음이 정답과 같은 자리에 있어요.")
                        legendRow(atom: "ㅏ", hint: .present, title: "다른 자리예요", detail: "정답 단어에 포함되지만 자리가 달라요.")
                        legendRow(atom: "ㅁ", hint: .absent, title: "포함 안 돼요", detail: "정답 단어에 포함되지 않아요.")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("쌍자음·겹받침·이중 모음은 낱개로 나뉘어요")
                            .font(.headline)
                        Text("예를 들어 'ㄲ'은 'ㄱ' + 'ㄱ'으로, 'ㅘ'는 'ㅗ' + 'ㅏ'로 나눠져서 각각 따로 힌트를 받아요. 그래서 겹받침이나 쌍자음이 있는 단어는 한 글자가 두 칸 이상을 차지할 수 있어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("게임 방법")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func legendRow(atom: Character, hint: LetterHint, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            GameGridCellView(cell: GridCell(atom: atom, hint: hint), size: legendCellSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    GameHelpView()
}
