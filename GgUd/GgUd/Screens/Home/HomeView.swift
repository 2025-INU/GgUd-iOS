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
    @State private var showPromiseActionPopup = false
    @State private var navigateToCreateAppointment = false
    @State private var inviteCodeInput = ""
    @State private var isJoiningWithCode = false
    @State private var isLoadingInvitePreview = false
    @State private var invitePreview: BackendPromise?
    @State private var invitePreviewError: String?
    @State private var joinAlertMessage: String?
    @State private var joinedPromiseId: Int64?
    @State private var presentedWaitingRoomPromiseId: Int64?
    @State private var selectedMidpointPromiseId: Int64?
    @State private var selectedMidpointInitialStatus: String?
    @State private var selectedMidpointInitialTitle: String?
    @State private var selectedMapPromise: HomePromise?
    @State private var promisePendingCompletion: HomePromise?
    @State private var promisePendingCancellation: HomePromise?
    @State private var isCompletingPromiseId: Int64?
    @State private var completionAlertMessage: String?
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
                                    CardContent(
                                        item: item,
                                        isScheduled: selectedSegment == .scheduled,
                                        isCompleting: isCompletingPromiseId == item.promiseId,
                                        onCompleteTapped: item.canComplete ? {
                                            promisePendingCompletion = item
                                        } : nil,
                                        onCancelTapped: item.canCancel ? {
                                            promisePendingCancellation = item
                                        } : nil
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .onTapGesture {
                                        guard let promiseId = item.promiseId else { return }

                                        if selectedSegment == .ongoing {
                                            selectedMapPromise = item
                                            return
                                        }

                                        if selectedSegment == .scheduled {
                                            Task {
                                                await openScheduledPromiseIfNeeded(promiseId: promiseId)
                                            }
                                        }
                                    }
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
                isLoadingPreview: isLoadingInvitePreview,
                invitePreview: invitePreview,
                invitePreviewError: invitePreviewError,
                onPaste: {
                    inviteCodeInput = UIPasteboard.general.string ?? ""
                },
                onJoin: {
                    Task {
                        await joinWithInviteCode()
                    }
                }
            )
            .presentationDetents([.height(420)])
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
        .alert("약속 종료", isPresented: Binding(
            get: { promisePendingCompletion != nil },
            set: { if !$0 { promisePendingCompletion = nil } }
        ), presenting: promisePendingCompletion) { item in
            Button("취소", role: .cancel) { promisePendingCompletion = nil }
            Button("종료", role: .destructive) {
                Task {
                    await completePromise(item)
                }
            }
        } message: { item in
            Text("\(item.title) 약속을 종료할까요? 종료 후에는 진행중인 약속에서 사라져요.")
        }
        .alert("약속 취소", isPresented: Binding(
            get: { promisePendingCancellation != nil },
            set: { if !$0 { promisePendingCancellation = nil } }
        ), presenting: promisePendingCancellation) { item in
            Button("닫기", role: .cancel) { promisePendingCancellation = nil }
            Button("취소", role: .destructive) {
                Task {
                    await cancelPromise(item)
                }
            }
        } message: { item in
            Text("\(item.title) 약속을 취소할까요? 취소 후에는 예정된 약속에서 사라져요.")
        }
        .alert("약속 종료", isPresented: Binding(
            get: { completionAlertMessage != nil },
            set: { if !$0 { completionAlertMessage = nil } }
        )) {
            Button("확인", role: .cancel) { completionAlertMessage = nil }
        } message: {
            Text(completionAlertMessage ?? "")
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showPromiseActionPopup = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
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
        .overlay {
            if showPromiseActionPopup {
                PromiseActionPopup(
                    onJoin: {
                        showPromiseActionPopup = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showJoinSheet = true
                        }
                    },
                    onCreate: {
                        showPromiseActionPopup = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigateToCreateAppointment = true
                        }
                    },
                    onDismiss: {
                        showPromiseActionPopup = false
                    }
                )
            }
        }
        .task(id: userSession.backendAccessToken) {
            await loadPromises()
        }
        .onChange(of: inviteCodeInput) { _, _ in
            fetchInvitePreview()
        }
        .onChange(of: showJoinSheet) { _, isPresented in
            if isPresented {
                fetchInvitePreview()
            } else {
                inviteCodeInput = ""
                invitePreview = nil
                invitePreviewError = nil
                isLoadingInvitePreview = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .waitingRoomShouldReturnHome)) { _ in
            print("[Home] received waitingRoomShouldReturnHome")
            print("[Home] before return home joinedPromiseId:", joinedPromiseId as Any, "presentedWaitingRoomPromiseId:", presentedWaitingRoomPromiseId as Any)
            selectedSegment = .scheduled
            joinedPromiseId = nil
            selectedMidpointPromiseId = nil
            selectedMidpointInitialStatus = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                presentedWaitingRoomPromiseId = nil
                print("[Home] cleared presentedWaitingRoomPromiseId after waitingRoomShouldReturnHome")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("closeWaitingRoomFlow"))) { _ in
            print("[Home] received closeWaitingRoomFlow")
            print("[Home] before close flow joinedPromiseId:", joinedPromiseId as Any, "presentedWaitingRoomPromiseId:", presentedWaitingRoomPromiseId as Any)
            selectedSegment = .scheduled
            joinedPromiseId = nil
            selectedMidpointPromiseId = nil
            selectedMidpointInitialStatus = nil
            selectedMidpointInitialTitle = nil
            showJoinSheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                presentedWaitingRoomPromiseId = nil
                print("[Home] cleared presentedWaitingRoomPromiseId after closeWaitingRoomFlow")
            }
        }
        .background {
            ZStack {
                NavigationLink(
                    destination: CreateAppointmentView(),
                    isActive: $navigateToCreateAppointment
                ) {
                    EmptyView()
                }
                .hidden()

                NavigationLink(
                    destination: Group {
                        if let promiseId = presentedWaitingRoomPromiseId ?? joinedPromiseId {
                            WaitingRoomView(promiseId: promiseId)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { joinedPromiseId != nil },
                        set: {
                            print("[Home] waiting room link set isActive:", $0)
                            if !$0 {
                                joinedPromiseId = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    presentedWaitingRoomPromiseId = nil
                                    print("[Home] waiting room link cleared presentedWaitingRoomPromiseId from setter")
                                }
                            }
                        }
                    )
                ) {
                    EmptyView()
                }
                .hidden()

                NavigationLink(
                    destination: Group {
                        if let selectedMidpointPromiseId {
                            MidpointView(promiseId: selectedMidpointPromiseId, initialStatus: selectedMidpointInitialStatus, initialMidpointTitle: selectedMidpointInitialTitle)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { selectedMidpointPromiseId != nil },
                        set: {
                            if !$0 {
                                selectedMidpointPromiseId = nil
                                selectedMidpointInitialStatus = nil
                                selectedMidpointInitialTitle = nil
                            }
                        }
                    )
                ) {
                    EmptyView()
                }
                .hidden()

                NavigationLink(
                    destination: Group {
                        if let selectedMapPromise, let promiseId = selectedMapPromise.promiseId {
                            MapView(promiseId: promiseId, title: selectedMapPromise.title)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { selectedMapPromise != nil },
                        set: { if !$0 { selectedMapPromise = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
    }

    private var currentItems: [HomePromise] {
        selectedSegment == .ongoing ? ongoing : scheduled
    }

    @MainActor
    private func openScheduledPromiseIfNeeded(promiseId: Int64) async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            loadError = "로그인 정보가 없습니다."
            return
        }

        let tokenType = userSession.backendTokenType ?? "Bearer"

        let cachedMidpointTitle = UserDefaults.standard.string(forKey: "confirmed_midpoint_title_\(promiseId)")
        let statusResult: Result<PromiseStatusResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getPromiseStatus(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch statusResult {
        case let .success(statusResponse):
            let normalizedStatus = (statusResponse.status ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            if normalizedStatus == "PLACE_CONFIRMED" {
                print("[Home] promiseId \(promiseId) already PLACE_CONFIRMED. staying on home")
                await loadPromises()
                return
            }

            if ["SELECTING_MIDPOINT", "MIDPOINT_CONFIRMED", "ALL_LOCATIONS_SUBMITTED"].contains(normalizedStatus) {
                selectedMidpointInitialStatus = normalizedStatus
                selectedMidpointInitialTitle = cachedMidpointTitle
                selectedMidpointPromiseId = promiseId
                return
            }

            presentedWaitingRoomPromiseId = promiseId
            joinedPromiseId = promiseId

        case let .failure(error):
            print("[Home] failed to fetch latest promise status for promiseId \(promiseId):", error.localizedDescription)
            presentedWaitingRoomPromiseId = promiseId
            joinedPromiseId = promiseId
        }
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
                presentedWaitingRoomPromiseId = promiseId
                joinedPromiseId = promiseId
            } else {
                presentJoinAlert("약속 참여는 성공했지만 약속 정보를 불러오지 못했어요.")
            }

        case let .failure(error):
            presentJoinAlert(friendlyJoinErrorMessage(error))
        }
    }

    private func fetchInvitePreview() {
        let trimmed = inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard showJoinSheet else { return }

        guard trimmed.count == 6 else {
            invitePreview = nil
            invitePreviewError = nil
            isLoadingInvitePreview = false
            return
        }

        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            invitePreview = nil
            invitePreviewError = "로그인 정보가 없습니다. 다시 로그인해주세요."
            isLoadingInvitePreview = false
            return
        }

        isLoadingInvitePreview = true
        invitePreviewError = nil

        PromiseAPIClient.shared.getInviteInfo(
            inviteCode: trimmed,
            accessToken: accessToken,
            tokenType: userSession.backendTokenType ?? "Bearer"
        ) { result in
            DispatchQueue.main.async {
                guard inviteCodeInput.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed else { return }
                isLoadingInvitePreview = false

                switch result {
                case let .success(promise):
                    print("[InvitePreview] promiseDateTime raw:", promise.promiseDateTime ?? "nil")
                    invitePreview = promise
                    invitePreviewError = nil
                case .failure:
                    invitePreview = nil
                    invitePreviewError = "초대 정보를 불러오지 못했어요.\n코드를 다시 확인해주세요."
                }
            }
        }
    }

    private func friendlyInvitePreviewErrorMessage(_ error: Error) -> String {
        if let apiError = error as? AuthAPIError {
            switch apiError {
            case let .server(statusCode, message):
                print("[InvitePreview] server error (\(statusCode)): \(message)")
                switch statusCode {
                case 401, 403:
                    return "로그인 정보가 만료되었어요. 다시 로그인해주세요."
                case 404:
                    return "유효하지 않은 초대 코드예요."
                case 500...599:
                    return "초대 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요."
                default:
                    return "초대 정보를 확인할 수 없어요. 다시 확인해주세요."
                }
            default:
                print("[InvitePreview] api error: \(apiError)")
                return "초대 정보를 확인할 수 없어요. 다시 확인해주세요."
            }
        }

        print("[InvitePreview] unexpected error: \(error)")
        return "초대 정보를 확인할 수 없어요. 다시 확인해주세요."
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
            switch result {
            case let .success(promises):
                Task {
                    let mapped = await enrichHomePromises(promises)
                    await MainActor.run {
                        isLoading = false
                        ongoing = mapped.filter { $0.segment == .ongoing }.map(\.promise)
                        scheduled = mapped.filter { $0.segment == .scheduled }.map(\.promise)
                    }
                }

            case let .failure(error):
                DispatchQueue.main.async {
                    isLoading = false
                    loadError = "약속 목록을 불러오지 못했습니다.\n\(error.localizedDescription)"
                    ongoing = []
                    scheduled = []
                }
            }
        }
    }

    private func enrichHomePromises(_ promises: [BackendPromise]) async -> [(segment: HomeSegment, promise: HomePromise)] {
        let tokenType = userSession.backendTokenType ?? "Bearer"
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            return promises.compactMap(mapToHomePromise)
        }

        var enriched: [(segment: HomeSegment, promise: HomePromise)] = []

        await withTaskGroup(of: (Int, (segment: HomeSegment, promise: HomePromise)?).self) { group in
            for (index, backendPromise) in promises.enumerated() {
                group.addTask {
                    let mapped = self.mapToHomePromise(backendPromise)
                    guard var mapped else { return (index, nil) }
                    guard let promiseId = mapped.promise.promiseId else { return (index, mapped) }

                    let avatars = await self.fetchParticipantAvatars(
                        promiseId: promiseId,
                        accessToken: accessToken,
                        tokenType: tokenType
                    )

                    mapped.promise = HomePromise(
                        promiseId: mapped.promise.promiseId,
                        title: mapped.promise.title,
                        date: mapped.promise.date,
                        time: mapped.promise.time,
                        people: mapped.promise.people,
                        place: mapped.promise.place,
                        statusText: mapped.promise.statusText,
                        confirmedPlace: mapped.promise.confirmedPlace,
                        canComplete: mapped.promise.canComplete,
                        canCancel: mapped.promise.canCancel,
                        participantAvatars: avatars
                    )
                    return (index, mapped)
                }
            }

            var buffer: [(Int, (segment: HomeSegment, promise: HomePromise)?)] = []
            for await item in group {
                buffer.append(item)
            }

            buffer
                .sorted { $0.0 < $1.0 }
                .forEach { _, mapped in
                    if let mapped {
                        enriched.append(mapped)
                    }
                }
        }

        return enriched
    }

    private func fetchParticipantAvatars(
        promiseId: Int64,
        accessToken: String,
        tokenType: String
    ) async -> [HomeParticipantAvatar] {
        let result: Result<[PromiseParticipantResponse], Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getParticipants(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case let .success(participants):
            return participants.map { participant in
                HomeParticipantAvatar(
                    userId: participant.userId,
                    profileImageURL: participant.profileImageUrl,
                    profileImageData: participant.userId == userSession.kakaoUserId ? userSession.profileImageData : nil
                )
            }
        case let .failure(error):
            print("[Home] failed to fetch participants for promiseId \(promiseId):", error.localizedDescription)
            return []
        }
    }

    private func mapToHomePromise(_ promise: BackendPromise) -> (segment: HomeSegment, promise: HomePromise)? {
        let rawStatus = (promise.status ?? "").uppercased()
        let promiseDate = parsePromiseDate(promise.promiseDateTime)
        let now = Date()
        let oneHourBeforeNow = now.addingTimeInterval(60 * 60)

        let hasConfirmedPlace = promise.confirmedPlaceName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        let segment: HomeSegment
        if rawStatus == "IN_PROGRESS" {
            segment = .ongoing
        } else if hasConfirmedPlace, let promiseDate, promiseDate <= oneHourBeforeNow {
            segment = .ongoing
        } else if let promiseDate, promiseDate > oneHourBeforeNow {
            segment = .scheduled
        } else if !hasConfirmedPlace, let promiseDate {
            segment = promiseDate <= oneHourBeforeNow ? .scheduled : .scheduled
        } else {
            return nil
        }

        let dateText = formatDate(promise.promiseDateTime)
        let timeText = formatTime(promise.promiseDateTime)
        let peopleCount = max(Int(promise.participantCount ?? 0), 1)
        let place = promise.confirmedPlaceName ?? "장소 미정"
        let statusText: String
        if segment == .ongoing {
            statusText = "진행중"
        } else if !hasConfirmedPlace {
            statusText = "생성중"
        } else {
            statusText = "확정됨"
        }

        return (
            segment,
            HomePromise(
                promiseId: promise.id,
                title: promise.title ?? "약속",
                date: dateText,
                time: timeText,
                people: peopleCount,
                place: place,
                statusText: statusText,
                confirmedPlace: promise.confirmedPlaceName,
                canComplete: segment == .ongoing && promise.hostId == userSession.kakaoUserId,
                canCancel: segment == .scheduled && promise.hostId == userSession.kakaoUserId,
                participantAvatars: Array(repeating: HomeParticipantAvatar(userId: nil, profileImageURL: nil, profileImageData: nil), count: peopleCount)
            )
        )
    }

    private func parsePromiseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: raw) { return date }

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        if let date = fallbackFormatter.date(from: raw) { return date }

        let localDateTimeFormatter = DateFormatter()
        localDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        localDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        localDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = localDateTimeFormatter.date(from: raw) { return date }

        let fractionalLocalDateTimeFormatter = DateFormatter()
        fractionalLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        fractionalLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        fractionalLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = fractionalLocalDateTimeFormatter.date(from: raw) { return date }

        let shortLocalDateTimeFormatter = DateFormatter()
        shortLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        shortLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = shortLocalDateTimeFormatter.date(from: raw) { return date }

        let spacedLocalDateTimeFormatter = DateFormatter()
        spacedLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        spacedLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        spacedLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = spacedLocalDateTimeFormatter.date(from: raw) { return date }

        let fractionalSpacedLocalDateTimeFormatter = DateFormatter()
        fractionalSpacedLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        fractionalSpacedLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        fractionalSpacedLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        if let date = fractionalSpacedLocalDateTimeFormatter.date(from: raw) { return date }

        let shortSpacedLocalDateTimeFormatter = DateFormatter()
        shortSpacedLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortSpacedLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        shortSpacedLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return shortSpacedLocalDateTimeFormatter.date(from: raw)
    }

    private func formatDate(_ raw: String?) -> String {
        guard let raw else { return "-" }
        guard let date = parsePromiseDate(raw) else {
            return raw.prefix(10).description
        }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        outputFormatter.dateFormat = "yyyy-MM-dd"
        return outputFormatter.string(from: date)
    }

    private func formatTime(_ raw: String?) -> String {
        guard let date = parsePromiseDate(raw) else { return "--:--" }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        outputFormatter.dateFormat = "HH:mm"
        return outputFormatter.string(from: date)
    }

    @MainActor
    private func cancelPromise(_ item: HomePromise) async {
        guard let promiseId = item.promiseId else {
            completionAlertMessage = "약속 정보를 찾지 못했어요."
            promisePendingCancellation = nil
            return
        }

        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            completionAlertMessage = "로그인 정보가 없어요. 다시 로그인해주세요."
            promisePendingCancellation = nil
            return
        }

        isCompletingPromiseId = promiseId
        promisePendingCancellation = nil
        defer { isCompletingPromiseId = nil }

        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.cancelPromise(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer"
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .success:
            completionAlertMessage = "약속을 취소했어요."
            await loadPromises()
        case let .failure(error):
            completionAlertMessage = friendlyCancelPromiseErrorMessage(error)
        }
    }

    private func friendlyCancelPromiseErrorMessage(_ error: Error) -> String {
        guard let apiError = error as? AuthAPIError else {
            return "약속을 취소하지 못했어요. 잠시 후 다시 시도해주세요."
        }

        switch apiError {
        case let .server(statusCode, _):
            switch statusCode {
            case 401, 403:
                return "약속을 취소할 권한이 없거나 로그인 정보가 만료되었어요."
            case 404:
                return "약속 정보를 찾지 못했어요."
            case 409:
                return "지금 상태에서는 약속을 취소할 수 없어요."
            case 500...599:
                return "약속 취소 중 서버에 문제가 생겼어요. 잠시 후 다시 시도해주세요."
            default:
                return "약속을 취소하지 못했어요. 잠시 후 다시 시도해주세요."
            }
        default:
            return "약속을 취소하지 못했어요. 잠시 후 다시 시도해주세요."
        }
    }

    @MainActor
    private func completePromise(_ item: HomePromise) async {
        guard let promiseId = item.promiseId else {
            completionAlertMessage = "약속 정보를 찾지 못했어요."
            promisePendingCompletion = nil
            return
        }

        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            completionAlertMessage = "로그인 정보가 없어요. 다시 로그인해주세요."
            promisePendingCompletion = nil
            return
        }

        isCompletingPromiseId = promiseId
        promisePendingCompletion = nil
        defer { isCompletingPromiseId = nil }

        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.completePromise(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer"
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .success:
            print("[HomeComplete] success for promiseId:", promiseId)
            completionAlertMessage = "약속을 종료했어요."
            await loadPromises()
        case let .failure(error):
            print("[HomeComplete] failure for promiseId:", promiseId)
            print("[HomeComplete] error:", error.localizedDescription)
            completionAlertMessage = friendlyCompletePromiseErrorMessage(error)
        }
    }

    private func friendlyCompletePromiseErrorMessage(_ error: Error) -> String {
        guard let apiError = error as? AuthAPIError else {
            return "약속을 종료하지 못했어요. 잠시 후 다시 시도해주세요."
        }

        switch apiError {
        case let .server(statusCode, message):
            print("[HomeComplete] server error (\(statusCode)): \(message)")
            switch statusCode {
            case 401, 403:
                return "약속을 종료할 권한이 없거나 로그인 정보가 만료되었어요."
            case 404:
                return "약속 정보를 찾지 못했어요."
            case 409:
                return "지금 상태에서는 약속을 종료할 수 없어요."
            case 500...599:
                return "약속 종료 중 서버에 문제가 생겼어요. 잠시 후 다시 시도해주세요."
            default:
                return "약속을 종료하지 못했어요. 잠시 후 다시 시도해주세요."
            }
        default:
            return "약속을 종료하지 못했어요. 잠시 후 다시 시도해주세요."
        }
    }
}

private struct PromiseActionPopup: View {
    let onJoin: () -> Void
    let onCreate: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 0) {
                Text("약속")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(hex: "#111827"))
                    .padding(.top, 28)

                Text("원하시는 기능을 선택해주세요.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "#6B7280"))
                    .padding(.top, 10)

                HStack(spacing: 12) {
                    popupButton(title: "약속 참여", action: onJoin)
                    popupButton(title: "약속 생성", action: onCreate)
                }
                .padding(.top, 28)
                .padding(.bottom, 28)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: 327)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 12)
            .padding(.horizontal, 24)
        }
    }

    private func popupButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "#2563EB"))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(hex: "#EFF6FF"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "#BFDBFE"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
    let isLoadingPreview: Bool
    let invitePreview: BackendPromise?
    let invitePreviewError: String?
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

            Group {
                if isLoadingPreview {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("초대 정보를 불러오는 중...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.subText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                } else if let invitePreview {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(invitePreview.title ?? "약속")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        HStack(spacing: 12) {
                            Label(formatDate(invitePreview.promiseDateTime), systemImage: "calendar")
                            Label(formatTime(invitePreview.promiseDateTime), systemImage: "clock")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.subText)

                        Text("주최자: \(invitePreview.hostNickname ?? "알 수 없음")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                } else if let invitePreviewError, !invitePreviewError.isEmpty {
                    Text(invitePreviewError)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
            }

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
                        .background(Color(hex: "#3B82F6"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isJoining || invitePreview == nil)
                .opacity((isJoining || invitePreview == nil) ? 0.6 : 1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background(AppColors.background)
    }

    private func formatDate(_ raw: String?) -> String {
        guard let raw else { return "-" }
        guard let date = parsePromiseDate(raw) else {
            return String(raw.prefix(10))
        }
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        outputFormatter.dateFormat = "yyyy-MM-dd"
        return outputFormatter.string(from: date)
    }

    private func formatTime(_ raw: String?) -> String {
        guard let raw else { return "--:--" }
        guard let date = parsePromiseDate(raw) else {
            return "--:--"
        }
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ko_KR")
        outputFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        outputFormatter.dateFormat = "HH:mm"
        return outputFormatter.string(from: date)
    }

    private func parsePromiseDate(_ raw: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: raw) {
            return date
        }

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        if let date = fallbackFormatter.date(from: raw) {
            return date
        }

        let localDateTimeFormatter = DateFormatter()
        localDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        localDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        localDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = localDateTimeFormatter.date(from: raw) {
            return date
        }

        let fractionalLocalDateTimeFormatter = DateFormatter()
        fractionalLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        fractionalLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        fractionalLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = fractionalLocalDateTimeFormatter.date(from: raw) {
            return date
        }

        let shortLocalDateTimeFormatter = DateFormatter()
        shortLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        shortLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = shortLocalDateTimeFormatter.date(from: raw) {
            return date
        }

        let spacedLocalDateTimeFormatter = DateFormatter()
        spacedLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        spacedLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        spacedLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = spacedLocalDateTimeFormatter.date(from: raw) {
            return date
        }

        let fractionalSpacedLocalDateTimeFormatter = DateFormatter()
        fractionalSpacedLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        fractionalSpacedLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        fractionalSpacedLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        if let date = fractionalSpacedLocalDateTimeFormatter.date(from: raw) {
            return date
        }

        let shortSpacedLocalDateTimeFormatter = DateFormatter()
        shortSpacedLocalDateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortSpacedLocalDateTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        shortSpacedLocalDateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return shortSpacedLocalDateTimeFormatter.date(from: raw)
    }
}


private extension Notification.Name {
    static let waitingRoomShouldReturnHome = Notification.Name("waitingRoomShouldReturnHome")
}
