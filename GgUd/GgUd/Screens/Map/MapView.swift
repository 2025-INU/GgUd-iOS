import SwiftUI
import CoreLocation
#if canImport(KakaoMapsSDK)
import KakaoMapsSDK
#endif

struct MapView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64
    let fallbackTitle: String

    @State private var titleText: String
    @State private var hostId: Int64?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var actionMessage: String?
    @State private var isShowingAlert = false
    @State private var arrivalBadgeText = "0/0 도착"
    @State private var directionCards: [ParticipantDirectionsCard] = []
    @State private var selectedRouteID: UUID?
    @State private var selectedRouteTitle: String?
    @State private var selectedRouteCoordinates: [CLLocationCoordinate2D] = []
    @State private var participantAnnotations: [DirectionsAnnotation] = []
    @State private var destinationAnnotation: DirectionsAnnotation?
    @State private var totalParticipantCount = 0
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
    @State private var isSheetExpanded = false
    @State private var shouldDrawKakaoMap = false
    @State private var currentDestinationCoordinate: CLLocationCoordinate2D?
    @StateObject private var promiseRealtime = PromiseRealtimeManager()
    @StateObject private var liveLocationManager = MapLiveLocationManager()
    @State private var navigateToSettlement = false
    @GestureState private var dragOffset: CGFloat = 0

    init(promiseId: Int64, title: String = "약속") {
        self.promiseId = promiseId
        self.fallbackTitle = title
        _titleText = State(initialValue: title)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            NavigationLink(
                destination: SettlementView(
                    promiseId: promiseId,
                    appointmentTitle: titleText,
                    hostId: hostId
                )
                .environmentObject(userSession),
                isActive: $navigateToSettlement
            ) {
                EmptyView()
            }
            .hidden()

            VStack(spacing: 0) {
                topBar

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let expandedHeight = min(500, height * 0.62)
                    let collapsedPeek = 260.0
                    let bottomInset: CGFloat = 14
                    let collapsedY = max(height - collapsedPeek - bottomInset, 0)
                    let expandedY = max(height - expandedHeight - bottomInset, 0)
                    let baseY = isSheetExpanded ? expandedY : collapsedY

                    ZStack(alignment: .top) {
                        mapSection
                            .frame(width: proxy.size.width, height: proxy.size.height)

                        bottomSheet
                            .frame(width: proxy.size.width, height: expandedHeight, alignment: .top)
                            .offset(y: baseY + dragOffset)
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = min(max(value.translation.height, -180), 180)
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 70
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                            if value.translation.height < -threshold {
                                                isSheetExpanded = true
                                            } else if value.translation.height > threshold {
                                                isSheetExpanded = false
                                            }
                                        }
                                    }
                            )
                    }
                }
            }
        }
        .task(id: promiseId) {
            shouldDrawKakaoMap = true
            await loadScreenData()
            connectRealtimeIfPossible()
            liveLocationManager.startTracking()
        }
        .refreshable {
            await loadScreenData()
        }
        .onDisappear {
            shouldDrawKakaoMap = false
            promiseRealtime.disconnect()
            liveLocationManager.stopTracking()
        }
        .onReceive(promiseRealtime.$latestLocationEvent.compactMap { $0 }) { event in
            Task {
                await handleLocationEvent(event)
            }
        }
        .onReceive(promiseRealtime.$latestStatusEvent.compactMap { $0 }) { event in
            Task {
                await handleStatusEvent(event)
            }
        }
        .onReceive(liveLocationManager.$coordinate.compactMap { $0 }) { coordinate in
            Task {
                await handleLocalCoordinateUpdate(coordinate)
            }
        }
        .onReceive(promiseRealtime.$connectionState) { state in
            guard state == .connected, let coordinate = liveLocationManager.coordinate else { return }
            promiseRealtime.publishMyLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        .alert("길찾기", isPresented: $isShowingAlert) {
            Button("확인", role: .cancel) {
                actionMessage = nil
            }
        } message: {
            Text(actionMessage ?? "알 수 없는 오류가 발생했어요.")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text("실시간 위치")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    Text(titleText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.subText)
                }

                Spacer(minLength: 0)

                Text(arrivalBadgeText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, 18)
                    .frame(height: 38)
                    .background(Color(hex: "#DBEAFE"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 18)

            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
        .background(Color.white)
    }

    private var mapSection: some View {
        Group {
#if canImport(KakaoMapsSDK)
            KakaoDirectionsMapView(
                draw: $shouldDrawKakaoMap,
                center: mapCenter,
                participants: participantAnnotations,
                destination: destinationAnnotation,
                selectedRouteCoordinates: selectedRouteCoordinates
            )
#else
            Rectangle()
                .fill(Color(red: 0.94, green: 0.95, blue: 0.97))
#endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(18)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "#D1D5DB"))
                .frame(width: 96, height: 6)
                .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("길찾기")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    if let loadError {
                        Text(loadError)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                    } else if !directionCards.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(directionCards) { card in
                                directionsCard(for: card)
                            }
                        }
                    } else if isLoading {
                        loadingCard
                    } else {
                        emptyCard
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 120)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: -2)
    }

    private func directionsCard(for card: ParticipantDirectionsCard) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ParticipantAvatarView(
                    profileImageURL: card.profileImageURL,
                    profileImageData: card.profileImageData,
                    size: 46
                )

                Text(card.nickname)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("경로 정보")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.text)
                } icon: {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }

                if card.routeOptions.isEmpty {
                    Text("경로 정보를 불러오지 못했어요.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.subText)
                } else {
                    VStack(spacing: 12) {
                        ForEach(card.routeOptions) { option in
                            routeOptionCard(option, isSelected: selectedRouteID == option.id)
                                .onTapGesture {
                                    selectRoute(option)
                                }
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#F3F4F6"))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func routeOptionCard(_ option: DirectionRouteOptionDisplay, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(option.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Spacer(minLength: 0)

                if isSelected {
                    Text("선택됨")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }

                if let summary = option.summaryText {
                    Text(summary)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.subText)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(option.steps) { step in
                    Text(step.displayText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.subText)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color(hex: "#EFF6FF") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? AppColors.primary : Color(hex: "#E5E7EB"), lineWidth: isSelected ? 1.5 : 1)
        )
    }

    private var loadingCard: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("길찾기 정보를 불러오는 중...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.subText)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color(hex: "#F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyCard: some View {
        Text("표시할 길찾기 정보가 없어요.")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppColors.subText)
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(Color(hex: "#F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private extension MapView {
    @MainActor
    func loadScreenData() async {
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

        async let mapResult: Result<PromiseMapDataResponse, Error> = withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMapData(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        async let arrivalResult: Result<ArrivalStatusResponse, Error> = withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getArrivalStatus(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        let (summaryValue, mapValue, arrivalValue) = await (summaryResult, mapResult, arrivalResult)

        switch summaryValue {
        case let .success(summary):
            titleText = summary.title ?? fallbackTitle
            hostId = summary.hostId
        case .failure:
            titleText = fallbackTitle
        }

        var participantsForDirections: [DirectionParticipant] = []
        var destinationCoordinate: CLLocationCoordinate2D?

        switch mapValue {
        case let .success(mapData):
            if let destination = mapData.destination,
               let lat = destination.latitude,
               let lon = destination.longitude {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                destinationCoordinate = coordinate
                currentDestinationCoordinate = coordinate
                destinationAnnotation = DirectionsAnnotation(
                    title: destination.name ?? "약속 장소",
                    coordinate: coordinate,
                    tint: .systemGreen,
                    userId: nil,
                    profileImageURL: nil,
                    profileImageData: nil
                )
                mapCenter = coordinate
            } else {
                currentDestinationCoordinate = nil
                destinationAnnotation = nil
            }

            let departureParticipants = mapData.participantDepartures ?? []
            let liveParticipants = mapData.currentLocations ?? []

            func participantKey(userId: Int64?, nickname: String?) -> String {
                if let userId { return "id:\(userId)" }
                return "name:\((nickname ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
            }

            var mergedParticipants: [ParticipantMarkerResponse] = []
            var liveByKey: [String: ParticipantMarkerResponse] = [:]

            for participant in liveParticipants {
                liveByKey[participantKey(userId: participant.userId, nickname: participant.nickname)] = participant
            }

            for participant in departureParticipants {
                let key = participantKey(userId: participant.userId, nickname: participant.nickname)
                if let live = liveByKey.removeValue(forKey: key) {
                    mergedParticipants.append(live)
                } else {
                    mergedParticipants.append(participant)
                }
            }

            if !liveByKey.isEmpty {
                mergedParticipants.append(contentsOf: liveByKey.values)
            }

            let remoteProfileImageDataByURL = await loadRemoteProfileImageDataMap(
                urls: mergedParticipants.compactMap { participant in
                    participant.profileImageUrl ?? currentUserProfileImageURL(for: participant.userId)
                }
            )

            participantAnnotations = mergedParticipants.compactMap { participant in
                guard let lat = participant.latitude, let lon = participant.longitude else { return nil }
                let profileImageURL = participant.profileImageUrl ?? currentUserProfileImageURL(for: participant.userId)
                return DirectionsAnnotation(
                    title: participant.nickname ?? "참여자",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    tint: .systemBlue,
                    userId: participant.userId,
                    profileImageURL: profileImageURL,
                    profileImageData: currentUserProfileImageData(for: participant.userId) ?? remoteProfileImageDataByURL[profileImageURL ?? ""]
                )
            }
            totalParticipantCount = max(mergedParticipants.count, departureParticipants.count, liveParticipants.count, participantAnnotations.count)

            participantsForDirections = mergedParticipants.compactMap { participant in
                guard let lat = participant.latitude, let lon = participant.longitude else { return nil }
                let profileImageURL = participant.profileImageUrl ?? currentUserProfileImageURL(for: participant.userId)
                return DirectionParticipant(
                    userId: participant.userId,
                    nickname: participant.nickname ?? "참여자",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    profileImageURL: profileImageURL,
                    profileImageData: currentUserProfileImageData(for: participant.userId) ?? remoteProfileImageDataByURL[profileImageURL ?? ""]
                )
            }

            if let current = participantsForDirections.first(where: { $0.userId == userSession.kakaoUserId }) ?? participantsForDirections.first(where: { $0.nickname == userSession.nickname }) ?? participantsForDirections.first {
                mapCenter = current.coordinate
            }

            if participantAnnotations.count > 1 || destinationAnnotation != nil {
            }
        case let .failure(error):
            loadError = error.localizedDescription
        }

        switch arrivalValue {
        case let .success(arrivals):
            print("[Arrivals] raw:", arrivals.raw)
            arrivalBadgeText = arrivalBadgeText(from: arrivals.raw, totalParticipants: max(totalParticipantCount, participantAnnotations.count, participantsForDirections.count))
        case let .failure(error):
            print("[Arrivals] error:", error.localizedDescription)
            arrivalBadgeText = "0/\(max(totalParticipantCount, participantAnnotations.count, participantsForDirections.count)) 도착"
        }

        if let destinationCoordinate {
            let selectedParticipants: [DirectionParticipant]
            if let currentUser = participantsForDirections.first(where: { $0.userId == userSession.kakaoUserId }) ?? participantsForDirections.first(where: { $0.nickname == userSession.nickname }) {
                selectedParticipants = [currentUser]
            } else if let firstParticipant = participantsForDirections.first {
                selectedParticipants = [firstParticipant]
            } else {
                selectedParticipants = []
            }

            var cards: [ParticipantDirectionsCard] = []
            for participant in selectedParticipants {
                let routeOptions = await loadDirections(
                    accessToken: accessToken,
                    tokenType: tokenType,
                    participant: participant,
                    destination: destinationCoordinate
                )
                cards.append(ParticipantDirectionsCard(nickname: participant.nickname, routeOptions: routeOptions))
                cards[cards.count - 1].profileImageURL = participant.profileImageURL
                cards[cards.count - 1].profileImageData = participant.profileImageData
            }
            directionCards = cards
            if let preferredTitle = selectedRouteTitle,
               let matching = cards.first?.routeOptions.first(where: { $0.title == preferredTitle }) {
                selectRoute(matching)
            } else if let firstOption = cards.first?.routeOptions.first {
                selectRoute(firstOption)
            } else {
                selectedRouteID = nil
                selectedRouteTitle = nil
                selectedRouteCoordinates = []
            }
        } else {
            directionCards = []
            selectedRouteID = nil
            selectedRouteTitle = nil
            selectedRouteCoordinates = []
        }

        isLoading = false
    }

    @MainActor
    func loadDirections(
        accessToken: String,
        tokenType: String,
        participant: DirectionParticipant,
        destination: CLLocationCoordinate2D
    ) async -> [DirectionRouteOptionDisplay] {
        let result: Result<DirectionsResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getDirections(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType,
                originLat: participant.coordinate.latitude,
                originLon: participant.coordinate.longitude,
                destLat: destination.latitude,
                destLon: destination.longitude
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case let .success(response):
            return (response.routeOptions ?? []).enumerated().map { index, option in
                DirectionRouteOptionDisplay(option: option, index: index)
            }
        case let .failure(error):
            print("[Directions] error for \(participant.nickname):", error.localizedDescription)
            return []
        }
    }


    @MainActor
    func selectRoute(_ option: DirectionRouteOptionDisplay) {
        selectedRouteID = option.id
        selectedRouteTitle = option.title
        selectedRouteCoordinates = option.polylineCoordinates
    }

    func connectRealtimeIfPossible() {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            print("[MapRealtime] missing backend access token")
            return
        }
        let tokenType = userSession.backendTokenType ?? "Bearer"
        print("[MapRealtime] connecting realtime for promiseId:", promiseId)
        promiseRealtime.connect(
            promiseId: promiseId,
            accessToken: accessToken,
            tokenType: tokenType,
            subscriptions: [.locations, .status]
        )
    }

    @MainActor
    func handleStatusEvent(_ event: PromiseStatusSocketEvent) async {
        print("[MapRealtime] received status type:", event.type)
        if let status = event.payload?.newStatus {
            print("[MapRealtime] newStatus:", status)
        }

        switch event.type {
        case "PROMISE_COMPLETED":
            actionMessage = event.message ?? "약속이 종료되어 정산 화면으로 이동해요."
            isShowingAlert = false
            navigateToSettlement = true
        default:
            await loadScreenData()
        }
    }

    @MainActor
    func handleLocationEvent(_ event: PromiseLocationSocketEvent) async {
        guard let latitude = event.latitude, let longitude = event.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        applyParticipantLocation(userId: event.userId, nickname: event.nickname, coordinate: coordinate)

        if event.userId == userSession.kakaoUserId || (!userSession.nickname.isEmpty && event.nickname == userSession.nickname) {
            await refreshCurrentUserDirections(using: coordinate, fallbackNickname: event.nickname)
        }
    }

    @MainActor
    func handleLocalCoordinateUpdate(_ coordinate: CLLocationCoordinate2D) async {
        let nickname = userSession.nickname.isEmpty ? "나" : userSession.nickname
        applyParticipantLocation(userId: userSession.kakaoUserId, nickname: nickname, coordinate: coordinate)

        if promiseRealtime.connectionState == .connected {
            promiseRealtime.publishMyLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }

        await refreshCurrentUserDirections(using: coordinate, fallbackNickname: nickname)
    }

    @MainActor
    func applyParticipantLocation(userId: Int64?, nickname: String?, coordinate: CLLocationCoordinate2D) {
        let resolvedNickname = (nickname?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? nickname! : "참여자")

        if let index = participantAnnotations.firstIndex(where: {
            if let existingUserId = $0.userId, let userId {
                return existingUserId == userId
            }
            return $0.title == resolvedNickname
        }) {
            let existing = participantAnnotations[index]
            participantAnnotations[index] = DirectionsAnnotation(
                title: existing.title,
                coordinate: coordinate,
                tint: existing.tint,
                userId: existing.userId ?? userId,
                profileImageURL: existing.profileImageURL,
                profileImageData: existing.profileImageData
            )
        } else {
            participantAnnotations.append(
                DirectionsAnnotation(
                    title: resolvedNickname,
                    coordinate: coordinate,
                    tint: .systemBlue,
                    userId: userId,
                    profileImageURL: currentUserProfileImageURL(for: userId),
                    profileImageData: currentUserProfileImageData(for: userId)
                )
            )
        }

        totalParticipantCount = max(totalParticipantCount, participantAnnotations.count)

        if userId == userSession.kakaoUserId || (!userSession.nickname.isEmpty && resolvedNickname == userSession.nickname) {
            mapCenter = coordinate
        }
    }

    @MainActor
    func refreshCurrentUserDirections(using coordinate: CLLocationCoordinate2D, fallbackNickname: String?) async {
        guard let destination = currentDestinationCoordinate,
              let accessToken = userSession.backendAccessToken,
              !accessToken.isEmpty else { return }

        let nickname = userSession.nickname.isEmpty ? (fallbackNickname ?? "나") : userSession.nickname
        let participant = DirectionParticipant(
            userId: userSession.kakaoUserId,
            nickname: nickname,
            coordinate: coordinate,
            profileImageURL: userSession.profileImageURL,
            profileImageData: userSession.profileImageData
        )
        let routeOptions = await loadDirections(
            accessToken: accessToken,
            tokenType: userSession.backendTokenType ?? "Bearer",
            participant: participant,
            destination: destination
        )
        directionCards = [
            ParticipantDirectionsCard(
                nickname: nickname,
                routeOptions: routeOptions,
                profileImageURL: userSession.profileImageURL,
                profileImageData: userSession.profileImageData
            )
        ]

        if let preferredTitle = selectedRouteTitle,
           let matching = routeOptions.first(where: { $0.title == preferredTitle }) {
            selectRoute(matching)
        } else if let firstOption = routeOptions.first {
            selectRoute(firstOption)
        } else {
            selectedRouteID = nil
            selectedRouteTitle = nil
            selectedRouteCoordinates = []
        }
    }

    func arrivalBadgeText(from raw: [String: JSONValue], totalParticipants: Int) -> String {
        let arrived = recursiveIntValue(for: ["arrivedCount", "arrivalCount", "arrived", "completedCount"], in: raw) ?? 0
        let total = recursiveIntValue(for: ["totalCount", "participantCount", "totalParticipants"], in: raw) ?? max(totalParticipants, 0)
        return "\(arrived)/\(max(total, 0)) 도착"
    }

    func recursiveIntValue(for keys: [String], in raw: [String: JSONValue]) -> Int? {
        for key in keys {
            if let direct = decodeInt(from: raw[key]) {
                return direct
            }
        }

        for value in raw.values {
            if case let .object(object) = value,
               let nested = recursiveIntValue(for: keys, in: object) {
                return nested
            }
        }

        return nil
    }

    func decodeInt(from value: JSONValue?) -> Int? {
        guard let value else { return nil }
        switch value {
        case let .number(number):
            return Int(number)
        case let .string(string):
            return Int(string)
        case let .object(object):
            return recursiveIntValue(for: ["count", "value", "total", "arrivedCount", "totalCount", "participantCount"], in: object)
        default:
            return nil
        }
    }

    func currentUserProfileImageURL(for userId: Int64?) -> String? {
        guard let userId, userId == userSession.kakaoUserId else { return nil }
        return userSession.profileImageURL
    }

    func currentUserProfileImageData(for userId: Int64?) -> Data? {
        guard let userId, userId == userSession.kakaoUserId else { return nil }
        return userSession.profileImageData
    }

    func loadRemoteProfileImageDataMap(urls: [String]) async -> [String: Data] {
        let uniqueURLs = Array(Set(urls.filter { !$0.isEmpty }))
        guard !uniqueURLs.isEmpty else { return [:] }

        return await withTaskGroup(of: (String, Data?).self) { group in
            for urlString in uniqueURLs {
                group.addTask {
                    guard let url = URL(string: urlString) else { return (urlString, nil) }
                    do {
                        let (data, response) = try await URLSession.shared.data(from: url)
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                        guard (200...299).contains(statusCode), !data.isEmpty else {
                            return (urlString, nil)
                        }
                        return (urlString, data)
                    } catch {
                        return (urlString, nil)
                    }
                }
            }

            var resolved: [String: Data] = [:]
            for await (urlString, data) in group {
                if let data {
                    resolved[urlString] = data
                }
            }
            return resolved
        }
    }
}

#if canImport(KakaoMapsSDK)
private struct KakaoDirectionsMapView: UIViewRepresentable {
    @Binding var draw: Bool
    let center: CLLocationCoordinate2D
    let participants: [DirectionsAnnotation]
    let destination: DirectionsAnnotation?
    let selectedRouteCoordinates: [CLLocationCoordinate2D]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> KMViewContainer {
        let view = KMViewContainer()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        context.coordinator.createController(view)
        return view
    }

    func updateUIView(_ uiView: KMViewContainer, context: Context) {
        context.coordinator.latestCenter = center
        context.coordinator.latestParticipants = participants
        context.coordinator.latestDestination = destination
        context.coordinator.latestRouteCoordinates = selectedRouteCoordinates

        let size = uiView.bounds.size
        if size.width > 10, size.height > 10 {
            context.coordinator.updateContainerSizeIfNeeded(size)
            context.coordinator.prepareIfNeeded()
        }

        if draw {
            context.coordinator.attachMapViewIfReady()
            context.coordinator.requestMapActivation()
            context.coordinator.syncIfPossible()
        } else {
            context.coordinator.controller?.pauseEngine()
            context.coordinator.controller?.resetEngine()
        }
    }

    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: Coordinator) {
        coordinator.controller?.pauseEngine()
        coordinator.controller?.resetEngine()
    }

    final class Coordinator: NSObject, MapControllerDelegate {
        var controller: KMController?
        var latestCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
        var latestParticipants: [DirectionsAnnotation] = []
        var latestDestination: DirectionsAnnotation?
        var latestRouteCoordinates: [CLLocationCoordinate2D] = []
        var containerSize: CGSize = .zero

        private var hasPreparedEngine = false
        private var hasAuthenticated = false
        private var hasAddedMapView = false
        private var isAddingMapView = false
        private let participantLayerID = "directions_participants"
        private let destinationLayerID = "directions_destination"
        private let destinationStyleID = "directions_destination_style"
        private var registeredStyleIDs: Set<String> = []

        func createController(_ view: KMViewContainer) {
            controller = KMController(viewContainer: view)
            controller?.delegate = self
        }

        func updateContainerSizeIfNeeded(_ size: CGSize) {
            guard size != containerSize else { return }
            containerSize = size
        }

        func prepareIfNeeded() {
            guard !hasPreparedEngine else { return }
            guard let controller, containerSize.width > 10, containerSize.height > 10 else { return }
            hasPreparedEngine = controller.prepareEngine()
        }

        func addViews() {
            guard hasPreparedEngine, hasAuthenticated, !hasAddedMapView, !isAddingMapView else { return }
            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in self?.addViews() }
                return
            }
            guard let controller else { return }
            if controller.getView("directions_mapview") != nil {
                hasAddedMapView = true
                isAddingMapView = false
                return
            }
            isAddingMapView = true
            let mapviewInfo = MapviewInfo(
                viewName: "directions_mapview",
                viewInfoName: "map",
                defaultPosition: MapPoint(longitude: latestCenter.longitude, latitude: latestCenter.latitude),
                defaultLevel: 7
            )
            let size = containerSize == .zero ? CGSize(width: 393, height: 852) : containerSize
            DispatchQueue.main.async { [weak self] in
                guard let self, let controller = self.controller else { return }
                controller.addView(mapviewInfo, viewSize: size)
            }
        }

        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            isAddingMapView = false
            hasAddedMapView = true
            guard let mapView = controller?.getView("directions_mapview") as? KakaoMap else { return }
            if containerSize != .zero {
                mapView.viewRect = CGRect(origin: .zero, size: containerSize)
            }
            requestMapActivation()
            syncIfPossible()
        }

        func addViewFailed(_ viewName: String, viewInfoName: String) {
            isAddingMapView = false
            hasAddedMapView = false
        }

        func authenticationSucceeded() {
            hasAuthenticated = true
            DispatchQueue.main.async { [weak self] in
                self?.attachMapViewIfReady()
            }
        }

        func authenticationFailed(_ errorCode: Int, desc: String) {
            print("[KakaoMap] authenticationFailed: \(errorCode) - \(desc)")
        }

        func containerDidResized(_ size: CGSize) {
            containerSize = size
            attachMapViewIfReady()
            guard let mapView = controller?.getView("directions_mapview") as? KakaoMap else { return }
            mapView.viewRect = CGRect(origin: .zero, size: size)
            requestMapActivation()
            syncIfPossible()
        }

        func attachMapViewIfReady() {
            guard hasPreparedEngine, hasAuthenticated, containerSize.width > 10, containerSize.height > 10 else { return }
            addViews()
        }

        func requestMapActivation() {
            guard let controller, hasPreparedEngine, hasAddedMapView else { return }
            controller.activateEngine()
        }

        func syncIfPossible() {
            guard let mapView = controller?.getView("directions_mapview") as? KakaoMap else { return }
            moveCameraIfPossible(mapView)

            let labelManager = mapView.getLabelManager()
            guard let participantLayer = ensureLabelLayer(labelManager, layerID: participantLayerID, zOrder: 10),
                  let destinationLayer = ensureLabelLayer(labelManager, layerID: destinationLayerID, zOrder: 20) else { return }

            participantLayer.visible = true
            destinationLayer.visible = true
            participantLayer.setClickable(false)
            destinationLayer.setClickable(false)
            participantLayer.clearAllItems()
            destinationLayer.clearAllItems()

            registerDestinationStyleIfNeeded(labelManager)

            for item in latestParticipants {
                let styleID = participantStyleID(for: item)
                registerParticipantStyleIfNeeded(labelManager, item: item, styleID: styleID)
                let options = PoiOptions(styleID: styleID, poiID: item.id.uuidString)
                options.rank = 1
                options.clickable = false
                options.addText(PoiText(text: item.title, styleIndex: 0))
                let poi = participantLayer.addPoi(option: options, at: MapPoint(longitude: item.coordinate.longitude, latitude: item.coordinate.latitude))
                poi?.show()
            }

            if let destination = latestDestination {
                let options = PoiOptions(styleID: destinationStyleID, poiID: destination.id.uuidString)
                options.rank = 0
                options.clickable = false
                let poi = destinationLayer.addPoi(option: options, at: MapPoint(longitude: destination.coordinate.longitude, latitude: destination.coordinate.latitude))
                poi?.show()
            }

            participantLayer.showAllPois()
            destinationLayer.showAllPois()
            mapView.refresh()
        }

        private func moveCameraIfPossible(_ mapView: KakaoMap) {
            let allCoordinates = latestParticipants.map(\.coordinate) + (latestDestination.map { [$0.coordinate] } ?? []) + latestRouteCoordinates
            let targetCenter: CLLocationCoordinate2D
            if allCoordinates.isEmpty {
                targetCenter = latestCenter
            } else {
                let lat = allCoordinates.map(\.latitude).reduce(0, +) / Double(allCoordinates.count)
                let lon = allCoordinates.map(\.longitude).reduce(0, +) / Double(allCoordinates.count)
                targetCenter = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            let cameraUpdate = CameraUpdate.make(target: MapPoint(longitude: targetCenter.longitude, latitude: targetCenter.latitude), zoomLevel: 9, mapView: mapView)
            mapView.moveCamera(cameraUpdate)
        }

        private func ensureLabelLayer(_ labelManager: LabelManager, layerID: String, zOrder: Int) -> LabelLayer? {
            if let layer = labelManager.getLabelLayer(layerID: layerID) { return layer }
            let options = LabelLayerOptions(layerID: layerID, competitionType: .none, competitionUnit: .symbolFirst, orderType: .rank, zOrder: zOrder)
            return labelManager.addLabelLayer(option: options)
        }

        private func participantStyleID(for item: DirectionsAnnotation) -> String {
            let identity = item.userId.map { "id_\($0)" } ?? item.title.replacingOccurrences(of: " ", with: "_")
            let hasProfile = item.profileImageData != nil || item.profileImageURL != nil
            return "directions_participant_\(identity)_\(hasProfile ? "profile" : "placeholder")"
        }

        private func registerParticipantStyleIfNeeded(_ labelManager: LabelManager, item: DirectionsAnnotation, styleID: String) {
            guard !registeredStyleIDs.contains(styleID) else { return }
            let iconStyle = PoiIconStyle(symbol: makeParticipantMarkerImage(item: item), anchorPoint: CGPoint(x: 0.5, y: 1.0))
            let textStyle = TextStyle(fontSize: 22, fontColor: UIColor(red: 0.07, green: 0.09, blue: 0.16, alpha: 1), strokeThickness: 4, strokeColor: .white)
            let lineStyle = PoiTextLineStyle(textStyle: textStyle)
            let poiTextStyle = PoiTextStyle(textLineStyles: [lineStyle])
            let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, textStyle: poiTextStyle, padding: 8, level: 0)
            labelManager.addPoiStyle(PoiStyle(styleID: styleID, styles: [perLevelStyle]))
            registeredStyleIDs.insert(styleID)
        }

        private func registerDestinationStyleIfNeeded(_ labelManager: LabelManager) {
            guard !registeredStyleIDs.contains(destinationStyleID) else { return }
            let iconStyle = PoiIconStyle(symbol: makeCircularSymbolImage(fill: .systemGreen, systemName: "mappin.circle.fill", size: CGSize(width: 48, height: 48), symbolPointSize: 14), anchorPoint: CGPoint(x: 0.5, y: 1.0))
            let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, padding: 0, level: 0)
            labelManager.addPoiStyle(PoiStyle(styleID: destinationStyleID, styles: [perLevelStyle]))
            registeredStyleIDs.insert(destinationStyleID)
        }

        private func makeParticipantMarkerImage(item: DirectionsAnnotation) -> UIImage? {
            if let data = item.profileImageData,
               let image = UIImage(data: data),
               let normalizedImage = normalizedMarkerSourceImage(from: image) {
                return circularAvatarImage(from: normalizedImage, tint: item.tint)
            }
            return makeAvatarPlaceholderImage(fill: item.tint, systemName: "person.fill", size: CGSize(width: 48, height: 48), symbolPointSize: 16)
        }

        private func circularAvatarImage(from image: UIImage, tint: UIColor) -> UIImage? {
            let size = CGSize(width: 48, height: 48)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: rect).addClip()
            image.draw(in: rect)
            let path = UIBezierPath(ovalIn: rect)
            UIColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()
            guard let rendered = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
            return normalizedMarkerSourceImage(from: rendered) ?? rendered
        }

        private func makeAvatarPlaceholderImage(fill: UIColor, systemName: String, size: CGSize, symbolPointSize: CGFloat) -> UIImage? {
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            fill.setFill()
            path.fill()
            UIColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()

            let config = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
            let iconImage = UIImage(systemName: systemName, withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            if let iconImage {
                let iconSize = min(symbolPointSize, min(size.width, size.height) - 8)
                let symbolRect = CGRect(
                    x: (size.width - iconSize) / 2,
                    y: (size.height - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                iconImage.draw(in: symbolRect)
            }
            guard let rendered = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
            return normalizedMarkerSourceImage(from: rendered) ?? rendered
        }

        private func makeCircularSymbolImage(fill: UIColor, systemName: String, size: CGSize, symbolPointSize: CGFloat) -> UIImage? {
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            let rect = CGRect(origin: .zero, size: size)
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1).cgColor,
                    UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1).cgColor
                ] as CFArray,
                locations: [0, 1]
            ) {
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: rect.minX, y: rect.minY),
                    end: CGPoint(x: rect.maxX, y: rect.maxY),
                    options: []
                )
            } else {
                fill.setFill()
                path.fill()
            }

            let iconImage: UIImage? = UIImage(named: "MapPinGlyph") ?? UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
            if let iconImage {
                let iconWidth: CGFloat = 13.5
                let iconHeight: CGFloat = 16.3
                let symbolRect = CGRect(
                    x: (size.width - iconWidth) / 2,
                    y: (size.height - iconHeight) / 2,
                    width: iconWidth,
                    height: iconHeight
                )
                iconImage.draw(in: symbolRect)
            }
            guard let rendered = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
            return normalizedMarkerSourceImage(from: rendered) ?? rendered
        }

        private func normalizedMarkerSourceImage(from image: UIImage) -> UIImage? {
            let format = UIGraphicsImageRendererFormat.default()
            format.opaque = false
            format.scale = max(image.scale, 1)
            let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
            let rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
            guard let pngData = rendered.pngData(), let normalized = UIImage(data: pngData) else {
                return rendered
            }
            return normalized
        }
    }
}
#endif

private struct DirectionsAnnotation: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let tint: UIColor
    let userId: Int64?
    let profileImageURL: String?
    let profileImageData: Data?
}

private struct DirectionParticipant {
    let userId: Int64?
    let nickname: String
    let coordinate: CLLocationCoordinate2D
    let profileImageURL: String?
    let profileImageData: Data?
}

private struct ParticipantDirectionsCard: Identifiable {
    let id = UUID()
    let nickname: String
    let routeOptions: [DirectionRouteOptionDisplay]
    var profileImageURL: String? = nil
    var profileImageData: Data? = nil
}

private struct DirectionRouteOptionDisplay: Identifiable {
    let id = UUID()
    let title: String
    let summaryText: String?
    let steps: [DirectionStepDisplay]
    let polylineCoordinates: [CLLocationCoordinate2D]

    init(option: RouteOptionResponse, index: Int) {
        title = "경로 \(index + 1)"

        var parts: [String] = []
        if let totalDuration = option.totalDuration {
            parts.append("\(totalDuration)분")
        }
        if let totalDistance = option.totalDistance {
            parts.append("\(totalDistance)m")
        }
        if let transferCount = option.transferCount {
            parts.append("환승 \(transferCount)회")
        }
        summaryText = parts.isEmpty ? nil : parts.joined(separator: " · ")
        let routeSteps = option.routes ?? []
        steps = routeSteps.map { DirectionStepDisplay(step: $0) }
        polylineCoordinates = routeSteps.flatMap { Self.parseLineString($0.linestring) }
    }

    private static func parseLineString(_ lineString: String?) -> [CLLocationCoordinate2D] {
        guard let lineString, !lineString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return lineString
            .split(separator: " ")
            .compactMap { segment in
                let values = segment.split(separator: ",")
                guard values.count == 2, let lon = Double(values[0]), let lat = Double(values[1]) else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
    }
}

private struct DirectionStepDisplay: Identifiable {
    let id = UUID()
    let displayText: String

    init(step: RouteStepResponse) {
        let prefix: String
        switch step.type {
        case "WALK":
            prefix = "[도보]"
        case "BUS":
            prefix = "[버스]"
        case "SUBWAY":
            prefix = "[지하철]"
        case "TRANSFER":
            prefix = "[환승]"
        default:
            prefix = "[경로]"
        }

        let instruction = step.instruction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "경로 정보"
        let duration = step.duration.map { " · \($0)분" } ?? ""
        let distance = step.distance.map { " · \($0)m" } ?? ""
        displayText = "\(prefix) \(instruction)\(duration)\(distance)"
    }
}

#Preview {
    MapView(promiseId: 1, title: "회사 동료 점심 모임")
        .environmentObject(UserSessionStore())
}

private extension CLLocationCoordinate2D {
    var key: String { "\(latitude),\(longitude)" }
}

private struct ParticipantAvatarView: View {
    let profileImageURL: String?
    let profileImageData: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if let profileImageData, let image = UIImage(data: profileImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let profileImageURL, let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 3)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        Circle()
            .fill(AppColors.primary)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}

private final class MapLiveLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 15
    }

    func startTracking() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            DispatchQueue.main.async {
                manager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestCoordinate = locations.last?.coordinate else { return }
        DispatchQueue.main.async { [weak self] in
            self?.coordinate = latestCoordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[MapRealtime] location error:", error.localizedDescription)
    }
}
