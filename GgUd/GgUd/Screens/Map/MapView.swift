import SwiftUI
import MapKit

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
    @State private var regionSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    @State private var isSheetExpanded = false
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
            await loadScreenData()
            connectRealtimeIfPossible()
            liveLocationManager.startTracking()
        }
        .refreshable {
            await loadScreenData()
        }
        .onDisappear {
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
        DirectionsMapRegionView(
            center: mapCenter,
            span: regionSpan,
            participants: participantAnnotations,
            destination: destinationAnnotation,
            selectedRouteCoordinates: selectedRouteCoordinates,
            isSheetExpanded: isSheetExpanded
        )
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

            participantAnnotations = mergedParticipants.compactMap { participant in
                guard let lat = participant.latitude, let lon = participant.longitude else { return nil }
                return DirectionsAnnotation(
                    title: participant.nickname ?? "참여자",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    tint: .systemBlue,
                    userId: participant.userId,
                    profileImageURL: participant.profileImageUrl ?? currentUserProfileImageURL(for: participant.userId),
                    profileImageData: currentUserProfileImageData(for: participant.userId)
                )
            }
            totalParticipantCount = max(mergedParticipants.count, departureParticipants.count, liveParticipants.count, participantAnnotations.count)

            participantsForDirections = mergedParticipants.compactMap { participant in
                guard let lat = participant.latitude, let lon = participant.longitude else { return nil }
                return DirectionParticipant(
                    userId: participant.userId,
                    nickname: participant.nickname ?? "참여자",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    profileImageURL: participant.profileImageUrl ?? currentUserProfileImageURL(for: participant.userId),
                    profileImageData: currentUserProfileImageData(for: participant.userId)
                )
            }

            if let current = participantsForDirections.first(where: { $0.userId == userSession.kakaoUserId }) ?? participantsForDirections.first(where: { $0.nickname == userSession.nickname }) ?? participantsForDirections.first {
                mapCenter = current.coordinate
            }

            if participantAnnotations.count > 1 || destinationAnnotation != nil {
                regionSpan = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
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
}

private struct DirectionsMapRegionView: UIViewRepresentable {
    let center: CLLocationCoordinate2D
    let span: MKCoordinateSpan
    let participants: [DirectionsAnnotation]
    let destination: DirectionsAnnotation?
    let selectedRouteCoordinates: [CLLocationCoordinate2D]
    let isSheetExpanded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let defaultRegion = MKCoordinateRegion(center: center, span: span)

        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        let annotations = participants + (destination.map { [$0] } ?? [])
        mapView.addAnnotations(annotations.map { annotation in
            let point = MKPointAnnotation()
            point.title = annotation.title
            point.coordinate = annotation.coordinate
            return AnnotatedPoint(base: annotation, point: point)
        }.map(\.point))

        context.coordinator.annotationMap = annotations.reduce(into: [:]) { partialResult, annotation in
            partialResult[annotation.coordinate.key] = annotation
        }

        if selectedRouteCoordinates.count >= 2 {
            let polyline = MKPolyline(coordinates: selectedRouteCoordinates, count: selectedRouteCoordinates.count)
            mapView.addOverlay(polyline)

            var visibleRect = polyline.boundingMapRect
            for annotation in annotations {
                let pointRect = MKMapRect(origin: MKMapPoint(annotation.coordinate), size: MKMapSize(width: 0, height: 0))
                visibleRect = visibleRect.union(pointRect)
            }

            let widthPadding = max(visibleRect.size.width * 0.25, 1200)
            let heightPadding = max(visibleRect.size.height * 0.35, 1200)
            let paddedRect = visibleRect.insetBy(dx: -widthPadding, dy: -heightPadding)
            let bottomPadding: CGFloat = isSheetExpanded ? 440 : 300
            mapView.setVisibleMapRect(
                paddedRect,
                edgePadding: UIEdgeInsets(top: 120, left: 48, bottom: bottomPadding, right: 48),
                animated: true
            )
        } else if abs(mapView.region.center.latitude - defaultRegion.center.latitude) > 0.0001 ||
                    abs(mapView.region.center.longitude - defaultRegion.center.longitude) > 0.0001 {
            mapView.setRegion(defaultRegion, animated: true)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var annotationMap: [String: DirectionsAnnotation] = [:]

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let point = annotation as? MKPointAnnotation else { return nil }
            let identifier = "DirectionsAnnotationView"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? AvatarAnnotationView) ?? AvatarAnnotationView(annotation: point, reuseIdentifier: identifier)
            view.annotation = point
            view.canShowCallout = false

            if let base = annotationMap[point.coordinate.key] {
                if base.tint == .systemGreen {
                    let size: CGFloat = 44
                    let symbolSize: CGFloat = 18
                    view.image = annotationImage(tint: base.tint, symbolName: "mappin.circle.fill", size: size, symbolSize: symbolSize)
                    view.avatarImageView.isHidden = true
                    view.centerOffset = CGPoint(x: 0, y: -size * 0.1)
                } else {
                    view.image = nil
                    view.avatarImageView.isHidden = false
                    view.configure(
                        profileImageURL: base.profileImageURL,
                        profileImageData: base.profileImageData,
                        tint: base.tint
                    )
                    view.centerOffset = CGPoint(x: 0, y: -4)
                }
            }

            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 6
                renderer.lineCap = .round
                renderer.lineJoin = .round
                renderer.alpha = 0.9
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        private func annotationImage(tint: UIColor, symbolName: String, size: CGFloat, symbolSize: CGFloat) -> UIImage? {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
                tint.setFill()
                UIBezierPath(ovalIn: rect).fill()

                let symbolConfig = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .bold)
                let symbol = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal)
                let symbolRect = CGRect(x: (size - symbolSize) / 2, y: (size - symbolSize) / 2, width: symbolSize, height: symbolSize)
                symbol?.draw(in: symbolRect)
            }
        }
    }

    private struct AnnotatedPoint {
        let base: DirectionsAnnotation
        let point: MKPointAnnotation
    }
}

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

private final class AvatarAnnotationView: MKAnnotationView {
    let avatarImageView = UIImageView()
    private var imageTask: URLSessionDataTask?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        avatarImageView.image = nil
        avatarImageView.backgroundColor = .systemBlue
    }

    func configure(profileImageURL: String?, profileImageData: Data?, tint: UIColor) {
        imageTask?.cancel()
        avatarImageView.backgroundColor = tint

        if let profileImageData, let image = UIImage(data: profileImageData) {
            avatarImageView.image = image
            return
        }

        guard let profileImageURL, let url = URL(string: profileImageURL) else {
            avatarImageView.image = Self.placeholderImage()
            return
        }

        avatarImageView.image = Self.placeholderImage()
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.avatarImageView.image = image
            }
        }
        imageTask?.resume()
    }

    private func setup() {
        frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        centerOffset = CGPoint(x: 0, y: -4)

        avatarImageView.frame = bounds
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = bounds.width / 2
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.layer.shadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        avatarImageView.layer.shadowOpacity = 1
        avatarImageView.layer.shadowRadius = 8
        avatarImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        avatarImageView.backgroundColor = .systemBlue
        avatarImageView.image = Self.placeholderImage()
        addSubview(avatarImageView)
    }

    private static func placeholderImage() -> UIImage? {
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.systemBlue.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            let symbol = UIImage(systemName: "person.fill", withConfiguration: symbolConfig)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            symbol?.draw(in: CGRect(x: 16, y: 14, width: 18, height: 18))
        }
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
