//
//  ContentView.swift
//  Kkodle
//
//  Created by 장주진 on 7/22/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel(answer: "우산", validWords: ["우산", "가방"])

    var body: some View {
        VStack {
            GameGridView(viewModel: viewModel)
            Spacer()
            GameKeyboardView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
