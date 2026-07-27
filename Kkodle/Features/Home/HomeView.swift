//
//  HomeView.swift
//  Kkodle
//
//  Created by 장주진 on 7/26/26.
//

import SwiftUI

struct HomeView: View {
    @State private var heartsStore = HeartsStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("꼬들꼬들")
                    .font(.largeTitle.bold())
                    .padding(.top, 40)

                HeartsIndicatorView(hearts: heartsStore.hearts)

                Spacer()

                NavigationLink {
                    DailyWordView()
                } label: {
                    ModeCard(title: "오늘의 단어", subtitle: "하루에 한 번, 오늘의 단어를 맞춰보세요", isEnabled: true)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EndlessModeView(heartsStore: heartsStore)
                } label: {
                    ModeCard(title: "무한 모드", subtitle: "한 단어씩, 몇 개까지 맞히는지 도전해보세요", isEnabled: true)
                }
                .buttonStyle(.plain)

                ModeCard(title: "시간 제한 모드", subtitle: "3분 안에 최대한 많이 맞춰보세요", isEnabled: false)
                ModeCard(title: "실시간 대결", subtitle: "다른 유저와 실시간으로 대결", isEnabled: false)

                Spacer()
            }
            .padding()
        }
    }
}

private struct ModeCard: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if !isEnabled {
                    Text("준비 중")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isEnabled ? 1 : 0.5)
        .foregroundStyle(Color.primary)
    }
}

#Preview {
    HomeView()
}
