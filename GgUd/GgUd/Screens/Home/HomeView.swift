import SwiftUI
import UIKit

struct HomeView: View {
    fileprivate enum HomeSegment {
        case ongoing
        case scheduled
    }

    @State private var selectedSegment: HomeSegment = .ongoing
    @State private var ongoing: [HomePromise] = []
    @State private var scheduled: [HomePromise] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showJoinSheet = false
    @State private var inviteCodeInput = ""
    @State private var isJoiningWithCode = false
    @State private var joinAlertMessage: String?
    @State private var joinedPromiseId: Int64?
    @EnvironmentObject private var userSession: UserSessionStore

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                HomeTopBarView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HomeSegmentedSwitch(selected: $selectedSegment)
                            .padding(.top, 12)
                            .padding(.horizontal, 24)

                        HStack {
                            Spacer()

                            Button {
                                showJoinSheet = true
                            } label: {
                                Text("초대 코드로 참여")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.primary)
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(AppColors.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 14)
                        .padding(.horizontal, 24)

                        if isLoading {
                            ProgressView()
                                .padding(.top, 40)
                        } else if let loadError {
                            Text(loadError)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "#6B7280"))
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                                .padding(.horizontal, 32)
                        } else if currentItems.isEmpty {
                            Text(emptyMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "#6B7280"))
                                .padding(.top, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(currentItems) { item in
                                    CardContent(item: item, isScheduled: selectedSegment == .scheduled)
                                }
                            }
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showJoinSheet) {
            InviteCodeJoinSheet(
                inviteCode: $inviteCodeInput,
                isJoining: isJoiningWithCode,
                onPaste: {
                    inviteCodeInput = UIPasteboard.general.string ?? ""
                },
                onJoin: {
                    Task {
                        await joinWithInviteCode()
                    }
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .alert("초대 코드", isPresented: Binding(
            get: { joinAlertMessage != nil },
            set: { if !$0 { joinAlertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { joinAlertMessage = nil }
        } message: {
            Text(sanitizedJoinAlertMessage(joinAlertMessage))
        }
        .overlay(alignment: .bottomTrailing) {
            NavigationLink {
                CreateAppointmentView()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#3B82F6"), Color(hex: "#2563EB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 28)
            .padding(.bottom, 108)
        }
        .task(id: userSession.backendAccessToken) {
            await loadPromises()
        }
        .background {
            NavigationLink(
                destination: Group {
                    if let joinedPromiseId {
                        WaitingRoomView(promiseId: joinedPromiseId)
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { joinedPromiseId != nil },
                    set: { if !$0 { joinedPromiseId = nil } }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
    }

    private var currentItems: [HomePromise] {
        selectedSegment == .ongoing ? ongoing : scheduled
    }

    private var emptyMessage: String {
        selectedSegment == .ongoing ? "진행중인 약속이 없습니다." : "예정된 약속이 없습니다."
    }

    @MainActor
    private func joinWithInviteCode() async {
        let trimmed = inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            presentJoinAlert("초대 코드를 입력해주세요.")
            return
        }

        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            presentJoinAlert("로그인 정보가 없습니다. 다시 로그인해주세요.")
            return
        }

        isJoiningWithCode = true
        defer { isJoiningWithCode = false }

        let result: Result<BackendPromise, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.joinPromise(
                inviteCode: trimmed,
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer"
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case let .success(promise):
            showJoinSheet = false
            inviteCodeInput = ""
            await loadPromises()
            if let promiseId = promise.id {
                joinedPromiseId = promiseId
            } else {
                presentJoinAlert("약속 참여는 성공했지만 약속 정보를 불러오지 못했어요.")
            }

        case let .failure(error):
            presentJoinAlert(friendlyJoinErrorMessage(error))
        }
    }

    private func presentJoinAlert(_ message: String) {
        joinAlertMessage = sanitizedJoinAlertMessage(message)
    }

    private func friendlyJoinErrorMessage(_ error: Error) -> String {
        if let apiError = error as? AuthAPIError {
            switch apiError {
            case let .server(statusCode, message):
                print("[InviteJoin] server error (\(statusCode)): \(message)")
                switch statusCode {
                case 401, 403:
                    return "로그인 정보가 만료되었어요. 다시 로그인해주세요."
                case 404:
                    return "초대 코드를 찾지 못했어요."
                case 409:
                    return "이미 참여 중인 약속이에요."
                case 500...599:
                    return "초대 코드로 참여하지 못했어요. 서버에 잠시 문제가 있어요. 조금 뒤에 다시 시도해주세요."
                default:
                    return "초대 코드로 참여하지 못했어요. 잠시 후 다시 시도해주세요."
                }
            default:
                print("[InviteJoin] api error: \(apiError)")
                return "초대 코드로 참여하지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }

        print("[InviteJoin] unexpected error: \(error)")
        return "초대 코드로 참여하지 못했어요. 잠시 후 다시 시도해주세요."
    }

    private func sanitizedJoinAlertMessage(_ message: String?) -> String {
        guard let message, !message.isEmpty else { return "" }

        if message.contains("\"success\":false") || message.contains("Internal server error") {
            return "초대 코드로 참여하지 못했어요. 서버에 잠시 문제가 있어요. 조금 뒤에 다시 시도해주세요."
        }

        return message
    }

    @MainActor
    private func loadPromises() async {
        guard userSession.isLoggedIn,
              let accessToken = userSession.backendAccessToken,
              !accessToken.isEmpty
        else {
            ongoing = []
            scheduled = []
            return
        }

        isLoading = true
        loadError = nil

        PromiseAPIClient.shared.getMyPromises(
            accessToken: accessToken,
            tokenType: userSession.backendTokenType ?? "Bearer"
        ) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case let .success(promises):
                    let mapped = promises.map(mapToHomePromise)
                    ongoing = mapped.filter { $0.segment == .ongoing }.map(\.promise)
                    scheduled = mapped.filter { $0.segment == .scheduled }.map(\.promise)

                case let .failure(error):
                    loadError = "약속 목록을 불러오지 못했습니다.\n\(error.localizedDescription)"
                    ongoing = []
                    scheduled = []
                }
            }
        }
    }

    private func mapToHomePromise(_ promise: BackendPromise) -> (segment: HomeSegment, promise: HomePromise) {
        let status = promise.status ?? ""
        let dateText = formatDate(promise.promiseDateTime)
        let timeText = formatTime(promise.promiseDateTime)
        let peopleCount = Int(promise.participantCount ?? 0)
        let place = promise.confirmedPlaceName ?? "장소 미정"
        let segment: HomeSegment = status == "IN_PROGRESS" ? .ongoing : .scheduled

        return (
            segment,
            HomePromise(
                title: promise.title ?? "약속",
                date: dateText,
                time: timeText,
                people: max(peopleCount, 0),
                place: place,
                statusText: segment == .ongoing ? "진행중" : "예정",
                confirmedPlace: promise.confirmedPlaceName
            )
        )
    }

    private func formatDate(_ raw: String?) -> String {
        guard let raw else { return "-" }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.dateFormat = "yyyy-MM-dd"

        if let date = isoFormatter.date(from: raw) ?? fallbackFormatter.date(from: raw) {
            return outputFormatter.string(from: date)
        }

        return raw.prefix(10).description
    }

    private func formatTime(_ raw: String?) -> String {
        guard let raw else { return "--:--" }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.dateFormat = "HH:mm"

        if let date = isoFormatter.date(from: raw) ?? fallbackFormatter.date(from: raw) {
            return outputFormatter.string(from: date)
        }

        return "--:--"
    }
}

private struct HomeSegmentedSwitch: View {
    @Binding var selected: HomeView.HomeSegment

    var body: some View {
        HStack(spacing: 0) {
            segment(title: "진행중인 약속", selected: selected == .ongoing) {
                selected = .ongoing
            }
            segment(title: "예정된 약속", selected: selected == .scheduled) {
                selected = .scheduled
            }
        }
        .padding(4)
        .background(Color(hex: "#F3F4F6"))
        .clipShape(Capsule())
    }

    private func segment(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selected ? Color.white : Color(hex: "#4B5563"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    selected
                    ? LinearGradient(
                        colors: [Color(hex: "#3B82F6"), Color(hex: "#2563EB")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct InviteCodeJoinSheet: View {
    @Binding var inviteCode: String
    let isJoining: Bool
    let onPaste: () -> Void
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("초대 코드로 참여")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("친구가 공유한 초대 코드를 붙여넣고 약속에 참여해보세요.")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.subText)

            TextField("초대 코드를 입력하세요", text: $inviteCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )

            HStack(spacing: 12) {
                Button(action: onPaste) {
                    Text("붙여넣기")
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

                Button(action: onJoin) {
                    Text(isJoining ? "참여 중..." : "참여하기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#38BDF8"), Color(hex: "#2563EB")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isJoining)
                .opacity(isJoining ? 0.6 : 1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background(AppColors.background)
    }
}
