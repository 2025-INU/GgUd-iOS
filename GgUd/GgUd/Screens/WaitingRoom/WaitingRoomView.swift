//
//  WaitingRoomView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct WaitingRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64

    @State private var navigateToMidpoint: Bool = false
    @State private var members: [WaitingMember] = []
    @State private var summary: PromiseSummaryResponse?
    @State private var isLoading = false
    @State private var loadError: String?

    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            // ✅ 기존 대기실 화면
            VStack(spacing: 0) {

                AppBar(title: "약속 대기방", onBack: { dismiss() })

                ScrollView {
                    WaitingRoomSummaryCard(
                        title: summary?.title ?? "약속 불러오는 중",
                        dateText: formattedSummaryDate,
                        timeText: formattedSummaryTime,
                        subtitle: "약속이 생성되었습니다!"
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 16) {

                        // 2) 친구 초대하기 섹션 (임시 자리)
                        Text("친구 초대하기")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        KakaoShareButton {
                            print("카카오 공유 탭")
                        }

                        Text("링크를 통해 친구들이 약속에 참여할 수 있어요")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.subText)

                        // 3) 참여한 친구
                        HStack {
                        Text("참여한 친구")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppColors.text)

                            Spacer()

                            Text("\(members.count)명")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                        }
                        .padding(.top, 12)

                        if isLoading && members.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        } else if let loadError {
                            Text(loadError)
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(members) { m in
                                NavigationLink {
                                    DepartureSetupView(promiseId: promiseId)
                                } label: {
                                    WaitingMemberRowCard(member: m)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        completionCTA
                            .padding(.top, 8)

                        NavigationLink(
                            destination: MidpointView(promiseId: promiseId),
                            isActive: $navigateToMidpoint
                        ) {
                            EmptyView()
                        }
                        .hidden()

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)

                Spacer()
            }
        }
        .task(id: promiseId) {
            await loadWaitingRoom()
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var allMembersDone: Bool {
        members.allSatisfy { $0.isDone }
    }

    private var formattedSummaryDate: String {
        guard let dateString = summary?.promiseDateTime,
              let date = ISO8601DateFormatter.withFractional.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        else { return "-" }
        return WaitingRoomDateFormatter.date.string(from: date)
    }

    private var formattedSummaryTime: String {
        guard let dateString = summary?.promiseDateTime,
              let date = ISO8601DateFormatter.withFractional.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        else { return "--:--" }
        return WaitingRoomDateFormatter.time.string(from: date)
    }

    private var completionCTA: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("모든 참여자가 위치를 입력했습니다!")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(red: 22/255, green: 163/255, blue: 74/255)) // 초록 텍스트

            Button {
                navigateToMidpoint = true
            } label: {
                Text("중간지점 확인하기")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(red: 22/255, green: 163/255, blue: 74/255)) // 진초록
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!allMembersDone)
            .opacity(allMembersDone ? 1 : 0.45)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 220/255, green: 252/255, blue: 231/255)) // 연한 초록 배경
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 134/255, green: 239/255, blue: 172/255), lineWidth: 1) // 연한 초록 테두리
        )
    }

    @MainActor
    private func loadWaitingRoom() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            loadError = "로그인 정보가 없습니다."
            return
        }

        isLoading = true
        loadError = nil

        let tokenType = userSession.backendTokenType ?? "Bearer"

        async let summaryResult: Result<PromiseSummaryResponse, Error> = withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getPromiseSummary(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        async let participantsResult: Result<[PromiseParticipantResponse], Error> = withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getParticipants(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        let (summaryResultValue, participantsResultValue) = await (summaryResult, participantsResult)

        switch summaryResultValue {
        case let .success(summary):
            self.summary = summary
        case let .failure(error):
            loadError = error.localizedDescription
        }

        switch participantsResultValue {
        case let .success(participants):
            members = participants.map { participant in
                let isMe = participant.userId == userSession.kakaoUserId
                return WaitingMember(
                    name: (participant.nickname ?? "사용자") + (isMe ? " (나)" : ""),
                    statusText: participant.locationSubmitted == true ? "위치 입력 완료" : "위치 입력 대기중",
                    isDone: participant.locationSubmitted == true
                )
            }
        case let .failure(error):
            loadError = error.localizedDescription
        }

        isLoading = false
    }

}

private enum WaitingRoomDateFormatter {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private extension ISO8601DateFormatter {
    static let withFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
