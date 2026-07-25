//
//  HeartsIndicatorView.swift
//  Kkodle
//
//  Created by 장주진 on 7/25/26.
//

import SwiftUI

struct HeartsIndicatorView: View {
    let hearts: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<HeartsStore.maxHearts, id: \.self) { index in
                Image(systemName: index < hearts ? "heart.fill" : "heart")
                    .foregroundStyle(index < hearts ? Color.red : Color.secondary.opacity(0.4))
                    .font(.system(size: 20))
            }
        }
    }
}

#Preview {
    HeartsIndicatorView(hearts: 2)
}
