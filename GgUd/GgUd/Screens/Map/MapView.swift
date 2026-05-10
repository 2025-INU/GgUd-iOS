import SwiftUI
import MapKit

struct MapView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64
    let fallbackTitle: String

    @State private var titleText: String
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var actionMessage: String?
    @State private var isShowingAlert = false
    @State private var arrivalBadgeText = "0/0 도착"
    @State private var directionCards: [ParticipantDirectionsCard] = []
    @State private var participantAnnotations: [DirectionsAnnotation] = []
    @State private var destinationAnnotation: DirectionsAnnotation?
    @State private var totalParticipantCount = 0
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
    @State private var regionSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    @State private var isSheetExpanded = false
    @GestureState private var dragOffset: CGFloat = 0

    init(promiseId: Int64, title: String = "약속") {
        self.promiseId = promiseId
        self.fallbackTitle = title
        _titleText = State(initialValue: title)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

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
        .task {
            await loadScreenData()
        }
        .refreshable {
            await loadScreenData()
        }
        .alert("길찾기", isPresented: $isShowingAlert) {
            Button("확인", role: .cancel) {
                actionMessage = nil
            }
        } message: {
            Text(actionMessage ?? "알 수 없는 오류가 발생했어요.")
        }
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
            destination: destinationAnnotation
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
                .padding(.bottom, 40)
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
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
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
                            routeOptionCard(option)
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

    private func routeOptionCard(_ option: DirectionRouteOptionDisplay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(option.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Spacer(minLength: 0)

                if let summary = option.summaryText {
                    Text(summary)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
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
                destinationAnnotation = DirectionsAnnotation(
                    title: destination.name ?? "약속 장소",
                    coordinate: coordinate,
                    tint: .systemGreen
                )
                mapCenter = coordinate
            } else {
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
                    tint: .systemBlue
                )
            }
            totalParticipantCount = max(mergedParticipants.count, departureParticipants.count, liveParticipants.count, participantAnnotations.count)

            participantsForDirections = mergedParticipants.compactMap { participant in
                guard let lat = participant.latitude, let lon = participant.longitude else { return nil }
                return DirectionParticipant(
                    userId: participant.userId,
                    nickname: participant.nickname ?? "참여자",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                )
            }

            if let current = participantsForDirections.first(where: { $0.nickname == userSession.nickname }) ?? participantsForDirections.first {
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
            if let currentUser = participantsForDirections.first(where: { $0.nickname == userSession.nickname }) {
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
            }
            directionCards = cards
        } else {
            directionCards = []
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
}

private struct DirectionsMapRegionView: View {
    let center: CLLocationCoordinate2D
    let span: MKCoordinateSpan
    let participants: [DirectionsAnnotation]
    let destination: DirectionsAnnotation?

    @State private var region: MKCoordinateRegion

    init(center: CLLocationCoordinate2D, span: MKCoordinateSpan, participants: [DirectionsAnnotation], destination: DirectionsAnnotation?) {
        self.center = center
        self.span = span
        self.participants = participants
        self.destination = destination
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }

    private var annotations: [DirectionsAnnotation] {
        var items = participants
        if let destination {
            items.append(destination)
        }
        return items
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                Circle()
                    .fill(Color(item.tint))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: item.tint == .systemGreen ? "mappin.circle.fill" : "person.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 8)
            }
        }
        .onAppear {
            region = MKCoordinateRegion(center: center, span: span)
        }
        .onChange(of: center.latitude) { _, _ in
            region = MKCoordinateRegion(center: center, span: span)
        }
        .onChange(of: center.longitude) { _, _ in
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

private struct DirectionsAnnotation: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let tint: UIColor
}

private struct DirectionParticipant {
    let userId: Int64?
    let nickname: String
    let coordinate: CLLocationCoordinate2D
}

private struct ParticipantDirectionsCard: Identifiable {
    let id = UUID()
    let nickname: String
    let routeOptions: [DirectionRouteOptionDisplay]
}

private struct DirectionRouteOptionDisplay: Identifiable {
    let id = UUID()
    let title: String
    let summaryText: String?
    let steps: [DirectionStepDisplay]

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
        steps = (option.routes ?? []).map { DirectionStepDisplay(step: $0) }
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
