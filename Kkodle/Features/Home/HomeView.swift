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
    @State private var battleSession: BattleSession?
    @State private var showGameHelp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("꼬들꼬들")
                    .font(.largeTitle.bold())
                    .padding(.top, 40)

                Button {
                    showGameHelp = true
                } label: {
                    Label("게임 방법 보기", systemImage: "questionmark.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                HeartsIndicatorView(heartsStore: heartsStore)

                if heartsStore.pendingCoupons > 0 {
                    CouponBanner(heartsStore: heartsStore)
                }

                Spacer()

                NavigationLink {
                    DailyWordView(heartsStore: heartsStore)
                } label: {
                    ModeCard(
                        title: "오늘의 단어",
                        subtitle: "하루에 한 번, 오늘의 단어를 맞춰보세요",
                        info: "매일 새로운 정답 단어가 나와요. 하루에 한 번만 도전할 수 있고, 6번의 기회 안에 5글자 한국어 단어를 맞혀야 해요. 성공하면 하트 1개를 보너스로 받아요.",
                        isEnabled: true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    endlessModeSession = EndlessModeSession()
                } label: {
                    ModeCard(
                        title: "무한 모드",
                        subtitle: "한 단어씩, 몇 개까지 맞히는지 도전해보세요",
                        info: "목숨 1개로 계속 도전하는 모드예요. 한 단어를 6번 안에 못 맞히면 그대로 종료되고, 몇 개까지 연속으로 맞혔는지 기록이 남아요. 하트를 쓰면 실수해도 이어서 도전할 수 있어요.",
                        isEnabled: true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    timeAttackSession = TimeAttackSession()
                } label: {
                    ModeCard(
                        title: "시간 제한 모드",
                        subtitle: "3분 안에 최대한 많이 맞춰보세요",
                        info: "3분의 제한 시간 안에 최대한 많은 단어를 맞혀보는 모드예요. 하트를 쓰면 시간을 늘릴 수 있어요.",
                        isEnabled: true
                    )
                }
                .buttonStyle(.plain)

                Button {
                    battleSession = BattleSession()
                } label: {
                    ModeCard(
                        title: "실시간 대결",
                        subtitle: "다른 유저와 실시간으로 대결",
                        info: "초대 코드로 방을 만들어 다른 유저와 1:1로 대결해요. 하나의 판을 서로 번갈아 맞히고, 먼저 정답을 맞히는 사람이 승리해요. 턴마다 20초의 제한 시간이 있어요.",
                        isEnabled: true
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
            .navigationDestination(item: $endlessModeSession) { _ in
                EndlessModeView(heartsStore: heartsStore)
            }
            .navigationDestination(item: $timeAttackSession) { _ in
                TimeAttackModeView(heartsStore: heartsStore)
            }
            .navigationDestination(item: $battleSession) { _ in
                BattleEntryView()
            }
            .sheet(isPresented: $showGameHelp) {
                GameHelpView()
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

private struct BattleSession: Identifiable, Hashable {
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
    let info: String
    let isEnabled: Bool
    @State private var showInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
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
        .alert(title, isPresented: $showInfo) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(info)
        }
    }
}

#Preview {
    HomeView()
}
