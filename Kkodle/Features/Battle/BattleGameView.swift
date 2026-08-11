//
//  BattleGameView.swift
//  Kkodle
//
//  Created by 장주진 on 8/10/26.
//

import SwiftUI

struct BattleGameView: View {
    @State private var viewModel: BattleGameViewModel
    @Environment(\.dismiss) private var dismiss

    init(code: String, myUserId: String, validWords: Set<String>, service: BattleRoomService) {
        _viewModel = State(initialValue: BattleGameViewModel(
            service: service,
            code: code,
            myUserId: myUserId,
            validWords: validWords
        ))
    }

    var body: some View {
        content
            .navigationTitle("실시간 대결")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(viewModel.room?.status == .playing)
            .onAppear { viewModel.startObserving() }
            .onDisappear { viewModel.stopObserving() }
    }

    @ViewBuilder
    private var content: some View {
        if let room = viewModel.room {
            switch room.status {
            case .waiting:
                waitingView
            case .playing:
                playingView
            case .ended:
                ZStack {
                    playingView
                    BattleResultOverlay(
                        didIWin: room.winnerId == viewModel.myUserId,
                        isDraw: room.winnerId == nil,
                        answerWord: room.answer,
                        onBack: {
                            viewModel.leaveRoom()
                            dismiss()
                        }
                    )
                }
            }
        } else {
            VStack {
                Spacer()
                ProgressView("연결 중...")
                Spacer()
            }
        }
    }

    private var waitingView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("상대방을 기다리는 중")
                .font(.headline)
            Text(viewModel.code)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .tracking(4)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 40)
            Text("이 코드를 친구에게 알려주세요")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView()
                .padding(.top, 8)
            Spacer()
            Button("나가기") {
                viewModel.leaveRoom()
                dismiss()
            }
            .foregroundStyle(.red)
            .padding(.bottom, 20)
        }
        .padding()
    }

    private var playingView: some View {
        VStack(spacing: 8) {
            turnIndicator
            BattleGridView(viewModel: viewModel)
            Spacer()
            BattleKeyboardView(viewModel: viewModel)
        }
    }

    private var turnIndicator: some View {
        Text(viewModel.isMyTurn ? "내 차례예요" : "상대방 차례예요")
            .font(.headline)
            .foregroundStyle(viewModel.isMyTurn ? Color.green : Color.secondary)
            .padding(.top, 8)
    }
}

private struct BattleGridView: View {
    let viewModel: BattleGameViewModel
    private let cellSize: CGFloat = 60

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: 8), count: viewModel.atomCount)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.gridRows.flatMap { $0 }) { cell in
                GameGridCellView(cell: cell, size: cellSize)
            }
        }
        .padding()
    }
}

private struct BattleKeyboardView: View {
    let viewModel: BattleGameViewModel
    @State private var isSending = false

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
        .disabled(!viewModel.isMyTurn)
        .opacity(viewModel.isMyTurn ? 1 : 0.5)
        .alert(
            "입력 오류",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in if !isPresented { viewModel.clearError() } }
            )
        ) {
            Button("확인", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
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

    private var isGuessComplete: Bool {
        viewModel.currentGuess.count == viewModel.atomCount
    }

    private var submitButton: some View {
        Button {
            isSending = true
            Task {
                await viewModel.submitGuess()
                isSending = false
            }
        } label: {
            HStack {
                if isSending { ProgressView().tint(.white) }
                Text("제출")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                LinearGradient(
                    colors: isGuessComplete
                        ? [Color(red: 1.0, green: 0.42, blue: 0.42), Color(red: 0.83, green: 0.18, blue: 0.42)]
                        : [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isGuessComplete || isSending)
        .padding(.top, 8)
    }

    private func backgroundColor(for atom: Character) -> Color {
        switch viewModel.bestHints[atom] {
        case .correct: .green
        case .present: .yellow
        case .absent: Color(white: 0.35)
        case nil: Color(white: 0.9)
        }
    }

    private func foregroundColor(for atom: Character) -> Color {
        viewModel.bestHints[atom] == nil ? Color.primary : Color.white
    }
}

private struct BattleResultOverlay: View {
    let didIWin: Bool
    let isDraw: Bool
    let answerWord: String
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text(isDraw ? "무승부" : (didIWin ? "승리!🎉" : "패배"))
                    .font(.title2.bold())
                    .foregroundStyle(isDraw ? Color.primary : (didIWin ? Color.green : Color.red))
                Text("정답은 \"\(answerWord)\" 였어요")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button("돌아가기", action: onBack)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 8)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(40)
        }
    }
}
