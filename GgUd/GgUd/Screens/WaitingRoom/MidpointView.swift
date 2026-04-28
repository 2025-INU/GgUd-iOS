//
//  MidpointView.swift
//  GgUd
//
//

import SwiftUI
import CoreLocation
#if canImport(KakaoMapsSDK)
import KakaoMapsSDK
#endif

struct MidpointView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64

    @State private var isSheetExpanded: Bool = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var shouldDrawMap: Bool = false
    @StateObject private var locationManager = MidpointLocationManager()
    @State private var mapCenterCoordinate: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var loadError: String?

    @State private var participants: [MarkerItem] = []
    @State private var recommendations: [PlaceItem] = []
    @State private var participantPoints: [CGPoint] = []
    @State private var midpointPoints: [CGPoint] = []

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let sheetHeight = min(360, height * 0.52)
                    let collapsedY = height - 160
                    let expandedY = height - sheetHeight
                    let baseY = isSheetExpanded ? expandedY : collapsedY

                    ZStack(alignment: .topLeading) {
                        mapPlaceholder
                            .frame(width: proxy.size.width, height: proxy.size.height)

                        infoCard
                            .padding(.top, 12)
                            .padding(.horizontal, 24)

                        bottomSheet
                            .frame(width: proxy.size.width, height: sheetHeight, alignment: .top)
                            .offset(y: baseY + dragOffset)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = min(max(value.translation.height, -90), 90)
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 120
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task(id: promiseId) {
            await loadMidpointData()
        }
    }

    private var topBar: some View {
        AppBar(title: "중간지점 결과", onBack: { dismiss() })
    }

    private var mapPlaceholder: some View {
        GeometryReader { geo in
            ZStack {
#if canImport(KakaoMapsSDK)
                KakaoMidpointMapView(draw: $shouldDrawMap, centerCoordinate: mapCenterCoordinate ?? locationManager.coordinate)
                    .frame(width: geo.size.width, height: geo.size.height)
#else
                Rectangle()
                    .fill(Color(red: 0.94, green: 0.95, blue: 0.97))
#endif

                ForEach(Array(participants.enumerated()), id: \.offset) { index, item in
                    if index < participantPoints.count {
                        participantMarker(item)
                            .position(
                                x: geo.size.width * participantPoints[index].x,
                                y: geo.size.height * participantPoints[index].y
                            )
                    }
                }

                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, _ in
                    if index < midpointPoints.count {
                        marker(.init(title: "추천", icon: "mappin", color: Color(red: 0.22, green: 0.62, blue: 0.96), coordinate: nil))
                            .position(
                                x: geo.size.width * midpointPoints[index].x,
                                y: geo.size.height * midpointPoints[index].y
                            )
                    }
                }
            }
            .clipped()
            .onAppear {
                shouldDrawMap = true
                locationManager.requestCurrentLocation()
            }
            .onDisappear {
                shouldDrawMap = false
            }
        }
    }

    private var infoCard: some View {
        VStack(spacing: 8) {
            Text("모이기 좋은 장소를 선택하세요")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("모든 참여자의 위치를 고려한 최적의 중간지점이에요")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.subText)

        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 15, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
    }

    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)

            Text("추천 중간지점")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if let loadError {
                Text(loadError)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else if recommendations.isEmpty {
                Text("추천된 중간지점이 아직 없습니다")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.subText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(recommendations) { item in
                    placeCard(item)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
    }

    private func participantMarker(_ item: MarkerItem) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(item.color)
                    .frame(width: 44, height: 44)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.text)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.95))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }

    private func marker(_ item: MarkerItem) -> some View {
        ZStack {
            Circle()
                .fill(item.color)
                .frame(width: 44, height: 44)

            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func placeCard(_ item: PlaceItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Text(item.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.subText)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                    Text(item.timeText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }

            Spacer()

            Circle()
                .fill(Color(red: 0.90, green: 0.96, blue: 1.0))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                )
        }
        .padding(14)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

private struct MarkerItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let coordinate: CLLocationCoordinate2D?
}

private struct PlaceItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let timeText: String
    let coordinate: CLLocationCoordinate2D?
}

#Preview {
    MidpointView(promiseId: 0)
        .environmentObject(UserSessionStore())
}

private extension MidpointView {
    @MainActor
    func loadMidpointData() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            loadError = "로그인 정보가 없습니다."
            return
        }

        isLoading = true
        loadError = nil

        let tokenType = userSession.backendTokenType ?? "Bearer"

        let startSelectionResult: Result<Void, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.startMidpointSelection(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch startSelectionResult {
        case .success:
            break
        case let .failure(error):
            loadError = error.localizedDescription
            isLoading = false
            return
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

        async let recommendationsResult: Result<MidpointRecommendationResponse, Error> = withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMidpointRecommendations(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        let (participantsValue, recommendationsValue) = await (participantsResult, recommendationsResult)

        switch participantsValue {
        case let .success(serverParticipants):
            let palette: [Color] = [
                Color(red: 0.97, green: 0.36, blue: 0.35),
                Color(red: 0.23, green: 0.52, blue: 0.98),
                Color(red: 0.21, green: 0.78, blue: 0.43),
                Color(red: 0.65, green: 0.44, blue: 0.96),
                Color(red: 0.95, green: 0.68, blue: 0.08)
            ]

            participants = serverParticipants.enumerated().compactMap { index, participant in
                guard let lat = participant.departureLatitude,
                      let lon = participant.departureLongitude else { return nil }

                return MarkerItem(
                    title: participant.nickname ?? "사용자",
                    icon: "person.fill",
                    color: palette[index % palette.count],
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                )
            }
        case let .failure(error):
            loadError = error.localizedDescription
            participants = []
        }

        switch recommendationsValue {
        case let .success(response):
            recommendations = (response.recommendedStations ?? []).map { station in
                let coordinate: CLLocationCoordinate2D?
                if let lat = station.latitude, let lon = station.longitude {
                    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                } else {
                    coordinate = nil
                }

                return PlaceItem(
                    title: station.stationName ?? "추천 역",
                    subtitle: station.lineName ?? "노선 정보 없음",
                    timeText: "평균 \((station.averageTravelTimeMinutes ?? 0))분",
                    coordinate: coordinate
                )
            }

            if let midpoint = response.calculatedMidpoint,
               let lat = midpoint.latitude,
               let lon = midpoint.longitude {
                mapCenterCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            } else {
                mapCenterCoordinate = averageCenterCoordinate()
            }
        case let .failure(error):
            if loadError == nil {
                loadError = error.localizedDescription
            }
            recommendations = []
            mapCenterCoordinate = averageCenterCoordinate()
        }

        updateOverlayPoints()
        isLoading = false
    }

    func averageCenterCoordinate() -> CLLocationCoordinate2D? {
        let coords = participants.compactMap(\.coordinate)
        guard !coords.isEmpty else { return nil }
        let avgLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let avgLon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }

    func updateOverlayPoints() {
        let participantCoordinates = participants.compactMap(\.coordinate)
        let recommendationCoordinates = recommendations.compactMap(\.coordinate)
        let allCoordinates = participantCoordinates + recommendationCoordinates

        guard !allCoordinates.isEmpty else {
            participantPoints = []
            midpointPoints = []
            return
        }

        let latitudes = allCoordinates.map(\.latitude)
        let longitudes = allCoordinates.map(\.longitude)
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        let latSpan = max(maxLat - minLat, 0.001)
        let lonSpan = max(maxLon - minLon, 0.001)

        func normalizedPoint(for coordinate: CLLocationCoordinate2D) -> CGPoint {
            let normalizedX = (coordinate.longitude - minLon) / lonSpan
            let normalizedY = 1 - ((coordinate.latitude - minLat) / latSpan)

            return CGPoint(
                x: min(max(normalizedX, 0.08), 0.92),
                y: min(max(normalizedY, 0.18), 0.82)
            )
        }

        participantPoints = participants.compactMap { item in
            guard let coordinate = item.coordinate else { return nil }
            return normalizedPoint(for: coordinate)
        }

        midpointPoints = recommendations.compactMap { item in
            guard let coordinate = item.coordinate else { return nil }
            return normalizedPoint(for: coordinate)
        }
    }
}


#if canImport(KakaoMapsSDK)
private struct KakaoMidpointMapView: UIViewRepresentable {
    @Binding var draw: Bool
    let centerCoordinate: CLLocationCoordinate2D?

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
        context.coordinator.latestCoordinate = centerCoordinate

        let size = uiView.bounds.size
        if size.width > 10, size.height > 10 {
            context.coordinator.updateContainerSizeIfNeeded(size)
            context.coordinator.prepareIfNeeded()
        } else {
            print("[KakaoMap] updateUIView skipped, bounds too small: \(size)")
        }

        if draw {
            context.coordinator.requestMapActivation()
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
        var latestCoordinate: CLLocationCoordinate2D?
        var containerSize: CGSize = .zero
        private var hasMovedCamera = false
        private var hasPreparedEngine = false

        func createController(_ view: KMViewContainer) {
            controller = KMController(viewContainer: view)
            controller?.delegate = self
        }

        func updateContainerSizeIfNeeded(_ size: CGSize) {
            guard size != containerSize else { return }
            containerSize = size
            print("[KakaoMap] container size updated: \(size)")
        }

        func prepareIfNeeded() {
            guard !hasPreparedEngine else { return }
            guard let controller else { return }
            guard containerSize.width > 10, containerSize.height > 10 else { return }
            let prepared = controller.prepareEngine()
            hasPreparedEngine = prepared
            print("[KakaoMap] prepareEngine returned: \(prepared)")
            print("[KakaoMap] controller state after prepare: \(controller.getStateDescMessage())")
        }

        func addViews() {
            let defaultPosition = MapPoint(longitude: 127.0276, latitude: 37.4979)
            let mapviewInfo = MapviewInfo(
                viewName: "midpoint_mapview",
                viewInfoName: "map",
                defaultPosition: defaultPosition,
                defaultLevel: 7
            )
            let size = containerSize == .zero ? CGSize(width: 393, height: 852) : containerSize
            controller?.addView(mapviewInfo, viewSize: size)
            print("[KakaoMap] addViews with size: \(size)")
            print("[KakaoMap] controller state after addViews: \(controller?.getStateDescMessage() ?? "unknown")")
        }

        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            print("[KakaoMap] addViewSucceeded: \(viewName) / \(viewInfoName)")
            guard let mapView = controller?.getView("midpoint_mapview") as? KakaoMap else { return }
            if containerSize != .zero {
                mapView.viewRect = CGRect(origin: .zero, size: containerSize)
            }
            requestMapActivation()
            moveCameraIfPossible()
        }

        func addViewFailed(_ viewName: String, viewInfoName: String) {
            print("[KakaoMap] addViewFailed: \(viewName) / \(viewInfoName)")
        }

        func authenticationSucceeded() {
            print("[KakaoMap] authenticationSucceeded")
            print("[KakaoMap] controller state on auth success: \(controller?.getStateDescMessage() ?? "unknown")")
            requestMapActivation()
        }

        func authenticationFailed(_ errorCode: Int, desc: String) {
            print("[KakaoMap] authenticationFailed: \(errorCode) - \(desc)")
        }

        func containerDidResized(_ size: CGSize) {
            containerSize = size
            print("[KakaoMap] containerDidResized: \(size)")
            guard let mapView = controller?.getView("midpoint_mapview") as? KakaoMap else { return }
            mapView.viewRect = CGRect(origin: .zero, size: size)
            requestMapActivation()
            moveCameraIfPossible()
        }

        func requestMapActivation() {
            guard let controller else { return }
            guard hasPreparedEngine else {
                print("[KakaoMap] activation deferred: engine not prepared")
                return
            }
            controller.activateEngine()
            print("[KakaoMap] activateEngine called")
            print("[KakaoMap] controller state after activate: \(controller.getStateDescMessage())")
        }

        func moveCameraIfPossible() {
            guard let mapView = controller?.getView("midpoint_mapview") as? KakaoMap else { return }
            let coordinate = latestCoordinate ?? CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
            let target = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
            let cameraUpdate = CameraUpdate.make(target: target, zoomLevel: 10, mapView: mapView)
            mapView.moveCamera(cameraUpdate)
            hasMovedCamera = true
            print("[KakaoMap] moveCamera to: \(coordinate.latitude), \(coordinate.longitude)")
        }
    }
}
#endif


private final class MidpointLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[KakaoMap] location error: \(error.localizedDescription)")
    }
}
