//
//  EndlessModeView.swift
//  Kkodle
//
//  Created by 장주진 on 7/26/26.
//

import SwiftUI

struct EndlessModeView: View {
    @State private var viewModel: EndlessGameViewModel

    init(heartsStore: HeartsStore) {
        let repository = WordRepository(atomCount: 5)
        _viewModel = State(initialValue: EndlessGameViewModel(repository: repository, heartsStore: heartsStore))
    }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    HeartsIndicatorView(hearts: viewModel.hearts)
                    Spacer()
                    Text("점수 \(viewModel.score)")
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                GameGridView(viewModel: viewModel.currentRound)
                Spacer()
                GameKeyboardView(viewModel: viewModel.currentRound)
            }

            if viewModel.currentRound.status == .lost && viewModel.runStatus == .playing {
                RoundLossPromptOverlay(
                    answerWord: viewModel.currentRound.answerWord,
                    canUseHeart: viewModel.canUseHeartToContinue,
                    onUseHeart: { viewModel.useHeartToContinue() },
                    onGiveUp: { viewModel.giveUp() }
                )
            }

            if viewModel.runStatus == .ended {
                EndlessResultOverlay(score: viewModel.score, answerWord: viewModel.currentRound.answerWord)
            }
        }
        .onChange(of: viewModel.currentRound.status) { _, _ in
            viewModel.handleRoundChange()
        }
        .navigationTitle("무한 모드")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RoundLossPromptOverlay: View {
    let answerWord: String
    let canUseHeart: Bool
    let onUseHeart: () -> Void
    let onGiveUp: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("시도를 다 썼어요 😥")
                    .font(.title2.bold())

                if canUseHeart {
                    Text("하트를 쓰면 이 단어에 한 번 더 도전할 수 있어요")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("하트 쓰고 한 번 더", action: onUseHeart)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text("정답은 \"\(answerWord)\" 였어요")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Button(canUseHeart ? "여기서 그만하기" : "기록 확인하기", action: onGiveUp)
                    .font(.headline)
                    .foregroundStyle(canUseHeart ? Color.primary : Color.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(canUseHeart ? Color.gray.opacity(0.2) : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(40)
        }
    }
}

private struct EndlessResultOverlay: View {
    let score: Int
    let answerWord: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("게임 종료")
                    .font(.title2.bold())
                Text("이번 기록: \(score)개")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                Text("정답은 \"\(answerWord)\" 였어요")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(40)
        }
    }
}

#Preview {
    EndlessModeView(heartsStore: HeartsStore(defaults: UserDefaults(suiteName: "preview.endless")!))
}
