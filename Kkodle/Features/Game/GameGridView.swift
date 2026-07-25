//
//  GameGridView.swift
//  Kkodle
//
//  Created by 장주진 on 7/24/26.
//

import SwiftUI

struct GameGridView: View {
    let viewModel: GameViewModel

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

private struct GameGridCellView: View {
    let cell: GridCell
    let size: CGFloat

    var body: some View {
        Text(cell.atom.map(String.init) ?? "")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(cell.hint == nil ? Color.primary : Color.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 8).fill(backgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor, lineWidth: 2))
    }

    private var backgroundColor: Color {
        switch cell.hint {
        case .correct: .green
        case .present: .yellow
        case .absent: .gray.opacity(0.6)
        case nil: .clear
        }
    }

    private var borderColor: Color {
        guard cell.hint == nil else { return .clear }
        return cell.atom == nil ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.8)
    }
}

#Preview {
    GameGridView(viewModel: previewViewModel())
}

private func previewViewModel() -> GameViewModel {
    let viewModel = GameViewModel(answer: "우산", validWords: ["우산", "가방"])
    for atom in HangulAtomizer.atomize("가방") ?? [] { viewModel.inputAtom(atom) }
    try? viewModel.submitGuess()
    for atom in (HangulAtomizer.atomize("우산") ?? []).prefix(3) { viewModel.inputAtom(atom) }
    return viewModel
}
