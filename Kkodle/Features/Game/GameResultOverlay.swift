//
//  GameResultOverlay.swift
//  Kkodle
//
//  Created by 장주진 on 7/25/26.
//

import SwiftUI

struct GameResultOverlay: View {
    let status: GameStatus
    let answerWord: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(status == .won ? "정답입니다! 🎉" : "아쉬워요 😢")
                    .font(.title2.bold())

                Text(status == .won ? "잘 맞췄어요!" : "정답은 \"\(answerWord)\" 였어요")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button("닫기", action: onDismiss)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(status == .won ? Color.green : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 8)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(40)
        }
    }
}

#Preview {
    GameResultOverlay(status: .won, answerWord: "가방", onDismiss: {})
}
