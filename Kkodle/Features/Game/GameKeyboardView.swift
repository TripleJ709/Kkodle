//
//  GameKeyboardView.swift
//  Kkodle
//
//  Created by 장주진 on 7/24/26.
//

import SwiftUI

struct GameKeyboardView: View {
    let viewModel: GameViewModel
    @State private var errorMessage: String?

    private static let rows: [(consonants: [Character], vowels: [Character])] = [
        (Array("ㅂㅈㄷㄱㅅ"), Array("ㅛㅕㅑ")),
        (Array("ㅁㄴㅇㄹㅎ"), Array("ㅗㅓㅏㅣ")),
        (Array("ㅋㅌㅊㅍ"), Array("ㅠㅜㅡ")),
    ]

    private let keyWidth: CGFloat = 34
    private let keySpacing: CGFloat = 4

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, row in
                combinedRow(consonants: row.consonants, vowels: row.vowels, showDelete: index == Self.rows.count - 1)
            }
            submitButton
        }
        .padding()
        .alert(
            "입력 오류",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in if !isPresented { errorMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func combinedRow(consonants: [Character], vowels: [Character], showDelete: Bool) -> some View {
        HStack(spacing: keySpacing) {
            ForEach(consonants, id: \.self) { jamoKey($0) }
            Spacer().frame(width: 10)
            ForEach(vowels, id: \.self) { jamoKey($0) }
            if showDelete {
                Spacer().frame(width: 10)
                deleteKey()
            }
        }
    }

    private func jamoKey(_ atom: Character) -> some View {
        Button {
            viewModel.inputAtom(atom)
        } label: {
            Text(String(atom))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(foregroundColor(for: atom))
                .frame(width: keyWidth, height: 42)
                .background(backgroundColor(for: atom))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func deleteKey() -> some View {
        Button {
            viewModel.deleteLastAtom()
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.primary)
                .frame(width: keyWidth, height: 42)
                .background(Color(white: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var submitButton: some View {
        Button(action: submit) {
            Text("제출")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.42, blue: 0.42), Color(red: 0.83, green: 0.18, blue: 0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(red: 0.83, green: 0.18, blue: 0.42).opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private func submit() {
        do {
            try viewModel.submitGuess()
        } catch SubmitError.incompleteGuess {
            errorMessage = "\(viewModel.atomCount)개를 다 입력해주세요."
        } catch SubmitError.invalidWord {
            errorMessage = "사전에 없는 단어예요."
        } catch {
            errorMessage = "알 수 없는 오류가 발생했어요."
        }
    }

    private func backgroundColor(for atom: Character) -> Color {
        switch viewModel.bestHints[atom] {
        case .correct: .green
        case .present: .yellow
        case .absent: .gray.opacity(0.6)
        case nil: Color(white: 0.9)
        }
    }

    private func foregroundColor(for atom: Character) -> Color {
        viewModel.bestHints[atom] == nil ? Color.primary : Color.white
    }
}

#Preview {
    GameKeyboardView(viewModel: GameViewModel(answer: "우산", validWords: ["우산"]))
}
