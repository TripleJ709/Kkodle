//
//  BattleEntryView.swift
//  Kkodle
//
//  Created by 장주진 on 8/10/26.
//

import SwiftUI

struct BattleEntryView: View {
    @State private var auth = AuthService()
    @State private var joinCode = ""
    @State private var isCreating = false
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var navigateCode: String?

    private let repository = WordRepository(atomCount: 5)
    private let service = BattleRoomService()

    var body: some View {
        VStack(spacing: 20) {
            Text("친구와 번갈아가며 같은 단어를 먼저 맞혀보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            Spacer()

            Button(action: createRoom) {
                HStack {
                    if isCreating { ProgressView().tint(.white) }
                    Text("방 만들기")
                }
                .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCreating || isJoining)

            VStack(spacing: 10) {
                TextField("6자리 코드 입력", text: $joinCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .font(.title3.monospaced())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: joinCode) { _, newValue in
                        let filtered = String(newValue.uppercased().prefix(6))
                        if filtered != joinCode { joinCode = filtered }
                    }

                Button(action: joinRoom) {
                    HStack {
                        if isJoining { ProgressView() }
                        Text("코드로 입장하기")
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
                .disabled(isCreating || isJoining || joinCode.count != 6)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("실시간 대결")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $navigateCode) { code in
            BattleGameView(code: code, myUserId: auth.userId ?? "", validWords: repository.validGuesses, service: service)
        }
    }

    private func createRoom() {
        errorMessage = nil
        isCreating = true
        Task {
            defer { isCreating = false }
            await auth.signInIfNeeded()
            guard let userId = auth.userId else {
                errorMessage = "로그인에 실패했어요. 네트워크를 확인해주세요."
                return
            }
            guard let answer = repository.randomAnswer() else {
                errorMessage = "단어를 불러오지 못했어요."
                return
            }
            do {
                let code = try service.createRoom(hostId: userId, answer: answer)
                navigateCode = code
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func joinRoom() {
        errorMessage = nil
        isJoining = true
        Task {
            defer { isJoining = false }
            await auth.signInIfNeeded()
            guard let userId = auth.userId else {
                errorMessage = "로그인에 실패했어요. 네트워크를 확인해주세요."
                return
            }
            do {
                try await service.joinRoom(code: joinCode, guestId: userId)
                navigateCode = joinCode
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        BattleEntryView()
    }
}
