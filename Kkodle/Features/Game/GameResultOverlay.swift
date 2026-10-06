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
    /// 정답 보상 안내 문구 (예: 오늘의 단어 하트 추가권). nil이면 표시하지 않습니다.
    var rewardText: String? = nil
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(status == .won ? "🎉" : "😢")
                    .font(.system(size: 44))

                Text(status == .won ? "정답입니다!" : "아쉬워요")
                    .font(.system(.title2, design: .rounded).weight(.bold))

                Text(status == .won ? "잘 맞췄어요!" : "정답은 \"\(answerWord)\" 였어요")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let rewardText {
                    Label(rewardText, systemImage: "heart.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.12), in: Capsule())
                }

                Button("닫기", action: onDismiss)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(status == .won ? KkodleTheme.ModeAccent.endless.accent : Color.gray)
                    .clipShape(Capsule())
                    .padding(.top, 8)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(40)
        }
    }
}

#Preview {
    GameResultOverlay(status: .won, answerWord: "가방", rewardText: "하트 추가권 +1 획득!", onDismiss: {})
}
