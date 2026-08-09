//
//  HomeView.swift
//  Kkodle
//
//  Created by 장주진 on 7/26/26.
//

import SwiftUI

struct HomeView: View {
    @State private var heartsStore = HeartsStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var endlessModeSession: EndlessModeSession?
    @State private var timeAttackSession: TimeAttackSession?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("꼬들꼬들")
                    .font(.largeTitle.bold())
                    .padding(.top, 40)

                HeartsIndicatorView(heartsStore: heartsStore)

                if heartsStore.pendingCoupons > 0 {
                    CouponBanner(heartsStore: heartsStore)
                }

                Spacer()

                NavigationLink {
                    DailyWordView(heartsStore: heartsStore)
                } label: {
                    ModeCard(title: "오늘의 단어", subtitle: "하루에 한 번, 오늘의 단어를 맞춰보세요", isEnabled: true)
                }
                .buttonStyle(.plain)

                Button {
                    endlessModeSession = EndlessModeSession()
                } label: {
                    ModeCard(title: "무한 모드", subtitle: "한 단어씩, 몇 개까지 맞히는지 도전해보세요", isEnabled: true)
                }
                .buttonStyle(.plain)

                Button {
                    timeAttackSession = TimeAttackSession()
                } label: {
                    ModeCard(title: "시간 제한 모드", subtitle: "3분 안에 최대한 많이 맞춰보세요", isEnabled: true)
                }
                .buttonStyle(.plain)

                ModeCard(title: "실시간 대결", subtitle: "다른 유저와 실시간으로 대결", isEnabled: false)

                Spacer()
            }
            .padding()
            .navigationDestination(item: $endlessModeSession) { _ in
                EndlessModeView(heartsStore: heartsStore)
            }
            .navigationDestination(item: $timeAttackSession) { _ in
                TimeAttackModeView(heartsStore: heartsStore)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                heartsStore.refresh()
            }
        }
    }
}

// Each tap of "무한 모드" creates a new session with a fresh identity, so
// .navigationDestination(item:) is forced to build a brand-new EndlessModeView
// (and therefore a brand-new EndlessGameViewModel) every time, rather than
// potentially reusing @State tied to the old NavigationLink's destination slot.
private struct EndlessModeSession: Identifiable, Hashable {
    let id = UUID()
}

private struct TimeAttackSession: Identifiable, Hashable {
    let id = UUID()
}

private struct CouponBanner: View {
    let heartsStore: HeartsStore
    @State private var showConfirmation = false

    var body: some View {
        HStack {
            Text("하트 추가권 \(heartsStore.pendingCoupons)개 보유 중")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("쿠폰 사용") {
                showConfirmation = true
            }
            .font(.caption.bold())
            .disabled(heartsStore.hearts >= HeartsStore.maxHearts)
        }
        .padding(.horizontal)
        .alert("쿠폰을 사용할까요?", isPresented: $showConfirmation) {
            Button("취소", role: .cancel) {}
            Button("사용") {
                heartsStore.redeemCoupon()
            }
        } message: {
            Text("쿠폰 1개를 써서 하트를 채웁니다.")
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
