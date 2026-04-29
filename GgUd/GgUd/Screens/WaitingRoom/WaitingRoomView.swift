//
//  WaitingRoomView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI
import UIKit
import KakaoSDKShare
import KakaoSDKTemplate

struct WaitingRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64

    @State private var navigateToMidpoint: Bool = false
    @State private var members: [WaitingMember] = []
    @State private var summary: PromiseSummaryResponse?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var isFetchingInviteCode = false
    @State private var cachedInviteCode: String?
    @State private var sharePayload: SharePayload?
    @State private var inviteAlertMessage: String?

    
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

                        KakaoShareButton(title: isFetchingInviteCode ? "초대 코드 불러오는 중..." : "카카오톡으로 링크 공유") {
                            Task {
                                await fetchInviteCodeAndShare()
                            }
                        }
                        .disabled(isFetchingInviteCode)

                        Button {
                            Task {
                                await fetchInviteCodeAndCopy()
                            }
                        } label: {
                            Text(isFetchingInviteCode ? "초대 코드 불러오는 중..." : "초대 코드 복사")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isFetchingInviteCode)

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

                        if allMembersDone && !members.isEmpty {
                            completionCTA
                                .padding(.top, 8)
                        }

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
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: [payload.message])
        }
        .alert("초대 코드", isPresented: Binding(
            get: { inviteAlertMessage != nil },
            set: { if !$0 { inviteAlertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { inviteAlertMessage = nil }
        } message: {
            Text(sanitizedInviteAlertMessage(inviteAlertMessage))
        }
    }
    
    private var allMembersDone: Bool {
        members.allSatisfy { $0.isDone }
    }

    private var formattedSummaryDate: String {
        guard let dateString = summary?.promiseDateTime,
              let date = WaitingRoomDateFormatter.parse(dateString)
        else { return "-" }
        return WaitingRoomDateFormatter.date.string(from: date)
    }

    private var formattedSummaryTime: String {
        guard let dateString = summary?.promiseDateTime,
              let date = WaitingRoomDateFormatter.parse(dateString)
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

    @MainActor
    private func fetchInviteCodeAndShare() async {
        guard !isFetchingInviteCode else { return }

        switch await fetchInviteCode() {
        case let .success(inviteCode):
            cachedInviteCode = inviteCode
            shareInviteCode(inviteCode)
        case let .failure(error):
            presentInviteAlert(friendlyInviteErrorMessage(error))
        }
    }

    @MainActor
    private func fetchInviteCodeAndCopy() async {
        guard !isFetchingInviteCode else { return }

        switch await fetchInviteCode() {
        case let .success(inviteCode):
            cachedInviteCode = inviteCode
            UIPasteboard.general.string = inviteCode
            presentInviteAlert("초대 코드가 복사되었어요.\n\(inviteCode)")
        case let .failure(error):
            presentInviteAlert(friendlyInviteErrorMessage(error))
        }
    }

    @MainActor
    private func fetchInviteCode() async -> Result<String, Error> {
        if let cachedInviteCode, !cachedInviteCode.isEmpty {
            return .success(cachedInviteCode)
        }

        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            return .failure(AuthAPIError.server(statusCode: 401, message: "로그인 정보가 없습니다. 다시 로그인해주세요."))
        }

        isFetchingInviteCode = true
        defer { isFetchingInviteCode = false }

        let tokenType = userSession.backendTokenType ?? "Bearer"

        return await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getInviteCode(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }
    }

    @MainActor
    private func shareInviteCode(_ inviteCode: String) {
        let promiseTitle = summary?.title ?? "약속"
        let message = "[GgUd] \(promiseTitle)에 초대되었어요.\n초대 코드: \(inviteCode)"
        let appLink = Link(iosExecutionParams: [
            "inviteCode": inviteCode,
            "promiseId": String(promiseId)
        ])
        let template = TextTemplate(
            text: message,
            link: appLink,
            buttonTitle: "GgUd에서 열기"
        )

        if ShareApi.isKakaoTalkSharingAvailable() {
            ShareApi.shared.shareDefault(templatable: template) { sharingResult, error in
                DispatchQueue.main.async {
                    if let error {
                        self.presentInviteAlert(self.friendlyInviteErrorMessage(error))
                        return
                    }

                    guard let sharingResult else {
                        self.presentInviteAlert("카카오톡 공유를 시작하지 못했어요. 잠시 후 다시 시도해주세요.")
                        return
                    }

                    UIApplication.shared.open(sharingResult.url, options: [:], completionHandler: nil)
                }
            }
        } else {
            sharePayload = SharePayload(message: message)
        }
    }

    private func friendlyInviteErrorMessage(_ error: Error) -> String {
        if let apiError = error as? AuthAPIError {
            switch apiError {
            case let .server(statusCode, message):
                print("[InviteCode] server error (\(statusCode)): \(message)")

                switch statusCode {
                case 401, 403:
                    return "로그인 정보가 만료되었어요. 다시 로그인해주세요."
                case 404:
                    return "약속 정보를 찾지 못했어요."
                case 500...599:
                    return "초대 코드를 불러오지 못했어요. 서버에 잠시 문제가 있어요. 조금 뒤에 다시 시도해주세요."
                default:
                    return "초대 코드를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                }
            default:
                print("[InviteCode] api error: \(apiError)")
                return "초대 코드를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }

        print("[InviteCode] unexpected error: \(error)")
        return "초대 코드를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
    }

    private func presentInviteAlert(_ message: String) {
        inviteAlertMessage = sanitizedInviteAlertMessage(message)
    }

    private func sanitizedInviteAlertMessage(_ message: String?) -> String {
        guard let message, !message.isEmpty else { return "" }

        if message.contains("\"success\":false") || message.contains("Internal server error") {
            return "초대 코드를 불러오지 못했어요. 서버에 잠시 문제가 있어요. 조금 뒤에 다시 시도해주세요."
        }

        return message
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

    static let localDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    static func parse(_ string: String) -> Date? {
        ISO8601DateFormatter.withFractional.date(from: string)
        ?? ISO8601DateFormatter().date(from: string)
        ?? localDateTime.date(from: string)
    }
}

private extension ISO8601DateFormatter {
    static let withFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}


private struct SharePayload: Identifiable {
    let id = UUID()
    let message: String
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
