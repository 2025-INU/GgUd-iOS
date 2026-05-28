//
//  MidpointView.swift
//  GgUd
//

import SwiftUI
import CoreLocation
#if canImport(KakaoMapsSDK)
import KakaoMapsSDK
#endif

private enum MidpointStage {
    case midpoint
    case finalPlace
}

private enum PlaceCategoryTab: String, CaseIterable, Identifiable {
    case all = "ALL"
    case restaurant = "RESTAURANT"
    case cafe = "CAFE"
    case bar = "BAR"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "전체"
        case .restaurant: return "식당"
        case .cafe: return "카페"
        case .bar: return "술집"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .bar: return "wineglass"
        }
    }
}

struct MidpointView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64
    let initialStatus: String?
    let initialMidpointTitle: String?

    @State private var isSheetExpanded: Bool = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var shouldDrawMap: Bool = false
    @StateObject private var locationManager = MidpointLocationManager()
    @StateObject private var promiseRealtime = PromiseRealtimeManager()
    @State private var mapCenterCoordinate: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var actionMessage: String?
    @State private var isShowingActionAlert = false
    @State private var isSubmittingSelection = false
    @State private var stage: MidpointStage = .midpoint
    @State private var selectedPlaceTab: PlaceCategoryTab = .all
    @State private var selectedMidpointTitle: String?
    @State private var currentMidpointFallbackTitle: String?
    @State private var isShowingAIModal = false
    @State private var aiPromptText = ""
    @State private var selectedAIQuery: String?
    @State private var currentPromiseStatus: String = ""
    @State private var isCurrentUserHost: Bool = false
    @State private var statusPollingTask: Task<Void, Never>?
    @State private var hasTriggeredReturnHome = false
    @State private var isShowingInfoCard = true
    @State private var infoCardHideTask: Task<Void, Never>?
    @State private var mapZoomLevel: Int = 11
    @State private var selectedFinalPlaceKeys: [String] = []

    @State private var participants: [MarkerItem] = []
    @State private var recommendations: [PlaceItem] = []
    @State private var finalPlaceRecommendations: [FinalPlaceItem] = []

    init(promiseId: Int64, initialStatus: String? = nil, initialMidpointTitle: String? = nil) {
        self.promiseId = promiseId
        self.initialStatus = initialStatus
        self.initialMidpointTitle = initialMidpointTitle
        _currentPromiseStatus = State(initialValue: (initialStatus ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased())
        let normalized = (initialStatus ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        _stage = State(initialValue: normalized == "MIDPOINT_CONFIRMED" || normalized == "PLACE_CONFIRMED" ? .finalPlace : .midpoint)
        _isShowingInfoCard = State(initialValue: !(normalized == "MIDPOINT_CONFIRMED" || normalized == "PLACE_CONFIRMED"))
        _selectedMidpointTitle = State(initialValue: initialMidpointTitle)
        _currentMidpointFallbackTitle = State(initialValue: initialMidpointTitle)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if stage == .finalPlace {
                    placeCategoryTabs
                }

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let bottomInset = proxy.safeAreaInsets.bottom
                    let isFinalPlaceStage = stage == .finalPlace
                    let sheetHeight = isFinalPlaceStage ? min(560, height * 0.76) : min(380, height * 0.56)
                    let sheetContainerHeight = sheetHeight + bottomInset + 18
                    let collapsedPeek = isFinalPlaceStage ? 310.0 : 170.0
                    let collapsedY = max(height - collapsedPeek, 0)
                    let expandedY = max(height - sheetHeight, 0)
                    let baseY = isSheetExpanded ? expandedY : collapsedY
                    let shouldShowFloatingCTA = stage == .finalPlace && !selectedFinalPlaceKeys.isEmpty

                    ZStack(alignment: .topLeading) {
                        if stage == .finalPlace && isLoading && finalPlaceRecommendations.isEmpty {
                            Color.white
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .overlay {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                }
                        } else {
                            mapPlaceholder
                                .frame(width: proxy.size.width, height: proxy.size.height)
                        }

                        VStack(spacing: 0) {
                            if stage == .midpoint, isShowingInfoCard {
                                infoCard
                                    .padding(.top, 12)
                                    .padding(.horizontal, 24)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            Spacer()
                        }

                        bottomSheet
                            .frame(width: proxy.size.width, height: sheetContainerHeight, alignment: .top)
                            .offset(y: baseY + dragOffset)
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = min(max(value.translation.height, -160), 160)
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 80
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            if value.translation.height < -threshold {
                                                isSheetExpanded = true
                                            } else if value.translation.height > threshold {
                                                isSheetExpanded = false
                                            }
                                        }
                                    }
                            )

                        if shouldShowFloatingCTA {
                            VStack {
                                Spacer()
                                floatingFinalPlaceCTA
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 18)
                            }
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(2)
                            .allowsHitTesting(true)
                        }
                    }
                }
            }

            if isShowingAIModal {
                aiRecommendationModal
                    .zIndex(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task(id: promiseId) {
            prepareMapLifecycle()
            if stage == .midpoint {
                scheduleInfoCardAutoHide()
            }
            await loadMidpointData()
            connectStatusSocketIfPossible()
            restartStatusPollingIfNeeded()
        }
        .onAppear {
            NotificationCenter.default.post(name: Notification.Name("hideCustomTabBar"), object: nil)
        }
        .onDisappear {
            tearDownMapLifecycle()
            statusPollingTask?.cancel()
            statusPollingTask = nil
            infoCardHideTask?.cancel()
            promiseRealtime.disconnect()
            NotificationCenter.default.post(name: Notification.Name("showCustomTabBar"), object: nil)
        }
        .onReceive(promiseRealtime.$latestStatusEvent.compactMap { $0 }) { event in
            Task { await handleStatusEvent(event) }
        }
        .onChange(of: stage) { _, newValue in
            if newValue == .midpoint {
                scheduleInfoCardAutoHide()
            } else {
                infoCardHideTask?.cancel()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingInfoCard = false
                }
            }
        }
        .alert("중간지점", isPresented: $isShowingActionAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(actionMessage ?? "")
        }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                if stage == .finalPlace {
                    Button(action: {
                        Task { await changeMidpointSelection() }
                    }) {
                        Image("BackNavIcon")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 13)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading || isSubmittingSelection)
                    .opacity((isLoading || isSubmittingSelection) ? 0.6 : 1)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("장소 추천")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        HStack(spacing: 6) {
                            Text(selectedMidpointDisplayText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppColors.subText)
                                .lineLimit(1)

                            Button(action: {
                                Task { await changeMidpointSelection() }
                            }) {
                                Text("변경")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.primary)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading || isSubmittingSelection)
                            .opacity((isLoading || isSubmittingSelection) ? 0.6 : 1)
                        }
                    }
                } else {
                    Text("중간지점 결과")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.text)
                }

                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    if stage == .finalPlace {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingAIModal = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.16, green: 0.80, blue: 0.54))
                                    .frame(width: 44, height: 44)
                                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)

                                Text("AI")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: returnHomeFromTopBar) {
                        Image("HomeNavIcon")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 18)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)
            .padding(.bottom, 17)
            .frame(height: 69)

            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
        .background(Color.white)
    }

    private func normalizedDisplayTitle(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var midpointTitleCacheKey: String {
        "confirmed_midpoint_title_\(promiseId)"
    }

    private func cacheMidpointTitleIfPossible(_ value: String?) {
        guard let normalized = normalizedDisplayTitle(value) else { return }
        UserDefaults.standard.set(normalized, forKey: midpointTitleCacheKey)
    }

    private func cachedMidpointTitle() -> String? {
        normalizedDisplayTitle(UserDefaults.standard.string(forKey: midpointTitleCacheKey))
    }

    private var selectedMidpointDisplayText: String {
        if let selected = normalizedDisplayTitle(selectedMidpointTitle) {
            return selected
        }
        if let fallback = normalizedDisplayTitle(currentMidpointFallbackTitle) {
            return fallback
        }
        if let cached = cachedMidpointTitle() {
            return cached
        }
        return "선택된 중간지점"
    }

    private var mapPlaceholder: some View {
        GeometryReader { geo in
            ZStack {
#if canImport(KakaoMapsSDK)
                KakaoMidpointMapView(
                    draw: $shouldDrawMap,
                    centerCoordinate: mapCenterCoordinate ?? locationManager.coordinate,
                    zoomLevel: mapZoomLevel,
                    participants: participants,
                    recommendations: mapRecommendationMarkers
                )
                .frame(width: geo.size.width, height: geo.size.height)
#else
                Rectangle()
                    .fill(Color(red: 0.94, green: 0.95, blue: 0.97))
#endif
            }
            .clipped()
        }
    }

    private func prepareMapLifecycle() {
        DispatchQueue.main.async {
            locationManager.requestCurrentLocation()
        }
        DispatchQueue.main.async {
            shouldDrawMap = true
        }
    }

    private func tearDownMapLifecycle() {
        DispatchQueue.main.async {
            shouldDrawMap = false
        }
    }

    private var aiRecommendationModal: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingAIModal = false
                    }
                }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(red: 0.16, green: 0.80, blue: 0.54))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("AI")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    Text("AI 장소 추천")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.text)
                        .padding(.top, 4)

                    Spacer(minLength: 0)

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingAIModal = false
                        }
                    }) {
                        Circle()
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppColors.subText)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Text("원하는 분위기나 장소 스타일을 자세히 설명해주세요. AI가 맞춤형 장소를 추천해드립니다.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.subText)
                    .lineSpacing(4)
                    .padding(.top, 28)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white)
                        )
                        .frame(height: 160)

                    if aiPromptText.isEmpty {
                        Text("예: 로맨틱하고 조용한 분위기의 카페나 레스토랑을 찾고 있어요. 야경이 보이면 더 좋겠어요.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.45, green: 0.49, blue: 0.57))
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }

                    TextEditor(text: $aiPromptText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.text)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(height: 160)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .onChange(of: aiPromptText) { _, newValue in
                            if newValue.count > 200 {
                                aiPromptText = String(newValue.prefix(200))
                            }
                        }
                }
                .padding(.top, 24)

                aiPromptChips
                    .padding(.top, 18)

                HStack {
                    Spacer()
                    Text("\(aiPromptText.count)/200")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.60, green: 0.65, blue: 0.71))
                }
                .padding(.top, 10)

                HStack(spacing: 14) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingAIModal = false
                        }
                    }) {
                        Text("취소")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task { await requestAIRecommendations() }
                    }) {
                        Text(isLoading ? "불러오는 중..." : "AI 추천 받기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
                                        ? [Color(red: 0.56, green: 0.86, blue: 0.76), Color(red: 0.49, green: 0.82, blue: 0.75)]
                                        : [Color(red: 0.16, green: 0.80, blue: 0.54), Color(red: 0.10, green: 0.71, blue: 0.54)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || isSubmittingSelection)
                    .opacity((aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || isSubmittingSelection) ? 0.75 : 1)
                }
                .padding(.top, 26)
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 24)
            .frame(maxWidth: 340)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 12)
            .padding(.horizontal, 24)
        }
    }

    private var aiPromptChips: some View {
        let chipTitles = ["로맨틱한 분위기", "조용한 카페", "활기찬 펍", "고급 레스토랑"]
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                aiPromptChip(chipTitles[0])
                aiPromptChip(chipTitles[1])
            }
            HStack(spacing: 10) {
                aiPromptChip(chipTitles[2])
                aiPromptChip(chipTitles[3])
            }
        }
    }

    private func aiPromptChip(_ title: String) -> some View {
        Button(action: {
            let trimmed = aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
            let appended = trimmed.isEmpty ? title : trimmed + ", " + title
            aiPromptText = String(appended.prefix(200))
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 0.08, green: 0.67, blue: 0.46))
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(Color(red: 0.91, green: 0.99, blue: 0.94))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var placeCategoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PlaceCategoryTab.allCases) { tab in
                    Button {
                        guard selectedPlaceTab != tab else { return }
                        selectedPlaceTab = tab
                        Task { await loadFinalPlaceRecommendations(tab: tab, query: selectedAIQuery) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 15, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(selectedPlaceTab == tab ? .white : AppColors.subText)
                        .padding(.horizontal, 20)
                        .frame(height: 44)
                        .background(selectedPlaceTab == tab ? AppColors.primary : Color.white.opacity(0.96))
                        .clipShape(Capsule())
                        .shadow(color: selectedPlaceTab == tab ? Color.black.opacity(0.12) : .clear, radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading || isSubmittingSelection)
                    .opacity((isLoading || isSubmittingSelection) ? 0.7 : 1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 14)
        }
        .background(Color.white)
    }

    private var infoCard: some View {
        VStack(spacing: 8) {
            Text(stage == .midpoint ? "모이기 좋은 장소를 선택하세요" : "최종 장소를 선택하세요")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text(stage == .midpoint ? "모든 참여자의 위치를 고려한 최적의 중간지점이에요" : "중간지점 주변에서 추천된 장소를 확인해보세요")
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
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .padding(.bottom, 28)

            HStack(alignment: .center, spacing: 12) {
                Text(stage == .midpoint ? "추천 중간지점" : "추천 장소")
                    .font(.system(size: stage == .midpoint ? 18 : 22, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Spacer()

            }
            .padding(.leading, stage == .finalPlace ? 30 : 24)
            .padding(.trailing, 24)
            .padding(.bottom, 20)

            if stage == .midpoint, !isCurrentUserHost, currentPromiseStatus == "MIDPOINT_CONFIRMED" {
                Text("호스트가 선택한 중간지점을 확인할 수 있어요")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }

            Group {
                if isLoading {
                    loadingContent
                } else if let loadError {
                    Text(loadError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if stage == .midpoint {
                    midpointListView
                } else {
                    finalPlaceListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .background(Color.white)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(topLeading: 24, bottomLeading: 0, bottomTrailing: 0, topTrailing: 24),
                style: .continuous
            )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
    }

    private var midpointListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if recommendations.isEmpty {
                    Text(midpointEmptyStateText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.subText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(recommendations) { item in
                        midpointCard(item)
                    }
                }
            }
            .padding(.bottom, 28)
        }
    }

    private var finalPlaceListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if finalPlaceRecommendations.isEmpty {
                    Text("추천된 장소가 아직 없습니다")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.subText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(finalPlaceRecommendations) { item in
                        finalPlaceCard(item)
                    }
                }
            }
            .padding(.bottom, 132)
        }
    }

    private var floatingFinalPlaceCTA: some View {
        Button(action: {
            Task { await confirmSelectedFinalPlaces() }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                Text("\(selectedFinalPlaceKeys.count)개 장소로 약속 확정하기")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: isSubmittingSelection
                        ? [Color(red: 0.70, green: 0.82, blue: 0.98), Color(red: 0.62, green: 0.77, blue: 0.97)]
                        : [Color(red: 0.18, green: 0.62, blue: 0.98), Color(red: 0.23, green: 0.51, blue: 0.96)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isSubmittingSelection)
        .opacity(isSubmittingSelection ? 0.75 : 1)
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            ProgressView()
                .scaleEffect(1.05)
            Text(stage == .finalPlace ? "추천 장소 불러오는 중..." : "추천 중간지점 불러오는 중...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.subText)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: stage == .finalPlace ? 320 : 220)
    }

    private var midpointEmptyStateText: String {
        let waitingStatuses: Set<String> = ["", "CREATED", "RECRUITING", "WAITING", "WAITING_ROOM", "WAITING_FOR_PARTICIPANTS", "READY", "LOCATION_COLLECTING"]
        if !isCurrentUserHost && waitingStatuses.contains(currentPromiseStatus) {
            return "호스트가 아직 중간지점을 선택하지 않았어요\n호스트가 중간지점을 선택하면 결과가 자동으로 표시돼요"
        }
        return "추천된 중간지점이 아직 없습니다"
    }

    private func midpointCard(_ item: PlaceItem) -> some View {
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

            Button(action: {
                Task { await confirmRecommendedMidpoint(item) }
            }) {
                trailingCircleArrow
            }
            .buttonStyle(.plain)
            .disabled(isSubmittingSelection || item.stationId == nil || !isCurrentUserHost)
            .opacity((isSubmittingSelection || item.stationId == nil || !isCurrentUserHost) ? 0.65 : 1)
        }
        .padding(14)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            focusMap(on: item.coordinate)
        }
    }

    private func finalPlaceSelectionKey(for item: FinalPlaceItem) -> String {
        if let placeId = item.placeId, !placeId.isEmpty {
            return placeId
        }
        return "\(item.title)|\(item.address)"
    }

    private func isFinalPlaceSelected(_ item: FinalPlaceItem) -> Bool {
        selectedFinalPlaceKeys.contains(finalPlaceSelectionKey(for: item))
    }

    private func toggleFinalPlaceSelection(_ item: FinalPlaceItem) {
        let key = finalPlaceSelectionKey(for: item)
        if let index = selectedFinalPlaceKeys.firstIndex(of: key) {
            selectedFinalPlaceKeys.remove(at: index)
        } else {
            selectedFinalPlaceKeys.append(key)
        }
    }

    private func finalPlaceCard(_ item: FinalPlaceItem) -> some View {
        let isSelected = isFinalPlaceSelected(item)

        return HStack(alignment: .top, spacing: 12) {
            placeThumbnail(for: item, isSelected: isSelected)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        if !item.summary.isEmpty {
                            Text(item.summary)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppColors.subText)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 0)

                    Button(action: {
                        toggleFinalPlaceSelection(item)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.133, green: 0.773, blue: 0.369))
                                .frame(width: 24, height: 24)

                            Image("SelectedPlaceMapPinIcon")
                                .resizable()
                                .renderingMode(.original)
                                .frame(width: 9, height: 11)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmittingSelection)
                    .opacity(isSubmittingSelection ? 0.65 : 1)
                }

                HStack(alignment: .center, spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                        Text(item.walkTimeText)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                    }

                    Spacer(minLength: 0)

                    if !item.categoryText.isEmpty {
                        Text(item.categoryText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppColors.subText)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color(red: 0.941, green: 0.976, blue: 1.0) : Color(red: 0.976, green: 0.98, blue: 0.984))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color(red: 0.055, green: 0.647, blue: 0.914) : Color(red: 0.898, green: 0.906, blue: 0.922), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            guard !isSubmittingSelection else { return }
            toggleFinalPlaceSelection(item)
        }
        .opacity(isSubmittingSelection ? 0.65 : 1)
    }

    @ViewBuilder
    private func placeThumbnail(for item: FinalPlaceItem, isSelected: Bool) -> AnyView {
        let baseThumbnail: AnyView
        if let imageURL = item.imageURL, let url = URL(string: imageURL) {
            baseThumbnail = AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(AppColors.primary)
                            )
                    }
                }
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
        } else {
            baseThumbnail = AnyView(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
                    .frame(width: 76, height: 76)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                    )
            )
        }

        return AnyView(
            ZStack {
                baseThumbnail

                if isSelected {
                    Circle()
                        .fill(Color(red: 0.15, green: 0.68, blue: 0.95))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
            }
            .frame(width: 76, height: 76)
        )
    }

    private var trailingCircleArrow: some View {
        Group {
            if isSubmittingSelection {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 36, height: 36)
            } else {
                Circle()
                    .fill(Color(red: 0.90, green: 0.96, blue: 1.0))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.primary)
                    )
            }
        }
    }


    private func scheduleInfoCardAutoHide() {
        infoCardHideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingInfoCard = true
        }
        infoCardHideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isShowingInfoCard = false
                }
            }
        }
    }

    private func loadRemoteProfileImageDataMap(urls: [String]) async -> [String: Data] {
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

    private func currentUserProfileImageURL(for userId: Int64?) -> String? {
        guard let userId, userId == userSession.kakaoUserId else { return nil }
        return userSession.profileImageURL
    }

    private func currentUserProfileImageData(for userId: Int64?) -> Data? {
        guard let userId, userId == userSession.kakaoUserId else { return nil }
        return userSession.profileImageData
    }

    private var mapRecommendationMarkers: [PlaceItem] {
        switch stage {
        case .midpoint:
            return recommendations
        case .finalPlace:
            return finalPlaceRecommendations.map {
                PlaceItem(
                    stationId: nil,
                    title: $0.title,
                    subtitle: $0.address,
                    timeText: "추천 장소",
                    coordinate: $0.coordinate
                )
            }
        }
    }

    @MainActor
    func loadMidpointData() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            loadError = "로그인 정보가 없습니다."
            return
        }

        isLoading = true
        loadError = nil

        let tokenType = userSession.backendTokenType ?? "Bearer"

        let statusResult: Result<PromiseStatusResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getPromiseStatus(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        let normalizedStatus: String = {
            switch statusResult {
            case let .success(response):
                return (response.status ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            case .failure:
                return ""
            }
        }()
        let effectiveStatus = mergedPromiseStatus(existing: currentPromiseStatus, incoming: normalizedStatus)
        currentPromiseStatus = effectiveStatus

        if effectiveStatus == "MIDPOINT_CONFIRMED" || effectiveStatus == "PLACE_CONFIRMED" {
            stage = .finalPlace
            isShowingInfoCard = false
        } else {
            stage = .midpoint
            finalPlaceRecommendations = []
        }

        let participantsResult: Result<[PromiseParticipantResponse], Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getParticipants(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch participantsResult {
        case let .success(serverParticipants):
            let palette: [Color] = [
                Color(red: 0.97, green: 0.36, blue: 0.35),
                Color(red: 0.23, green: 0.52, blue: 0.98),
                Color(red: 0.21, green: 0.78, blue: 0.43),
                Color(red: 0.65, green: 0.44, blue: 0.96),
                Color(red: 0.95, green: 0.68, blue: 0.08)
            ]

            isCurrentUserHost = serverParticipants.contains { participant in
                participant.userId == userSession.kakaoUserId && (participant.host ?? false)
            }

            let remoteProfileImageDataByURL = await loadRemoteProfileImageDataMap(
                urls: serverParticipants.compactMap { participant in
                    participant.profileImageUrl ?? currentUserProfileImageURL(for: participant.userId)
                }
            )

            participants = serverParticipants.enumerated().compactMap { index, participant in
                guard let lat = participant.departureLatitude,
                      let lon = participant.departureLongitude else { return nil }

                let resolvedUserId = participant.userId
                let profileImageURL = participant.profileImageUrl ?? currentUserProfileImageURL(for: resolvedUserId)
                return MarkerItem(
                    userId: resolvedUserId,
                    title: participant.nickname ?? "사용자",
                    icon: "person.fill",
                    color: palette[index % palette.count],
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    profileImageURL: profileImageURL,
                    profileImageData: currentUserProfileImageData(for: resolvedUserId) ?? remoteProfileImageDataByURL[profileImageURL ?? ""]
                )
            }
        case let .failure(error):
            loadError = error.localizedDescription
            participants = []
            isCurrentUserHost = false
        }

        restartStatusPollingIfNeeded()

        let shouldStartSelection: Bool = {
            guard isCurrentUserHost else { return false }
            switch effectiveStatus {
            case "", "CREATED", "RECRUITING", "WAITING", "WAITING_ROOM", "WAITING_FOR_PARTICIPANTS", "READY", "LOCATION_COLLECTING":
                return true
            default:
                return false
            }
        }()

        if shouldStartSelection {
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
                currentPromiseStatus = "SELECTING_MIDPOINT"
            case let .failure(error):
                loadError = error.localizedDescription
                isLoading = false
                return
            }
        } else {
            print("[Midpoint] skip startMidpointSelection for status: \(effectiveStatus), isHost: \(isCurrentUserHost)")
        }

        let mapDataResult: Result<PromiseMapDataResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMapData(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        var latestMapData: PromiseMapDataResponse?
        switch mapDataResult {
        case let .success(mapData):
            latestMapData = mapData
            let midpointNameFromMapData = mapData.destination?.name ?? mapData.recommendedMidpoints?.first?.name
            currentMidpointFallbackTitle = midpointNameFromMapData
            cacheMidpointTitleIfPossible(midpointNameFromMapData)
            applyMapData(mapData)
        case .failure:
            break
        }

        let guestWaitingStatuses: Set<String> = ["", "CREATED", "RECRUITING", "WAITING", "WAITING_ROOM", "WAITING_FOR_PARTICIPANTS", "READY", "LOCATION_COLLECTING"]
        if !isCurrentUserHost && guestWaitingStatuses.contains(effectiveStatus) {
            recommendations = []
            loadError = nil
            isLoading = false
            return
        }

        if effectiveStatus == "MIDPOINT_CONFIRMED" {
            let midpointNameFromMapData = normalizedDisplayTitle(latestMapData?.destination?.name)
                ?? normalizedDisplayTitle(latestMapData?.recommendedMidpoints?.first?.name)

            let midpointNameResult: Result<MidpointRecommendationResponse, Error> = await withCheckedContinuation { continuation in
                PromiseAPIClient.shared.getMidpointRecommendations(
                    promiseId: promiseId,
                    accessToken: accessToken,
                    tokenType: tokenType
                ) { result in
                    continuation.resume(returning: result)
                }
            }

            let midpointNameFromRecommendations: String?
            switch midpointNameResult {
            case let .success(response):
                midpointNameFromRecommendations = normalizedDisplayTitle(response.recommendedStations?.first?.stationName)
            case .failure:
                midpointNameFromRecommendations = nil
            }

            let resolvedMidpointTitle = midpointNameFromRecommendations ?? midpointNameFromMapData ?? cachedMidpointTitle()
            print("[Midpoint] resolved confirmed midpoint title:", resolvedMidpointTitle ?? "nil")
            selectedMidpointTitle = resolvedMidpointTitle
            currentMidpointFallbackTitle = resolvedMidpointTitle
            cacheMidpointTitleIfPossible(resolvedMidpointTitle)

            isLoading = false
            await loadFinalPlaceRecommendations(tab: selectedPlaceTab, query: selectedAIQuery)
            return
        }

        if effectiveStatus == "PLACE_CONFIRMED" {
            let resolvedPlaceConfirmedMidpointTitle = latestMapData?.destination?.name
                ?? latestMapData?.recommendedMidpoints?.first?.name
                ?? cachedMidpointTitle()
            selectedMidpointTitle = resolvedPlaceConfirmedMidpointTitle
            currentMidpointFallbackTitle = resolvedPlaceConfirmedMidpointTitle
            cacheMidpointTitleIfPossible(resolvedPlaceConfirmedMidpointTitle)
            isLoading = false
            returnHomeImmediatelyAfterPlaceConfirmed(source: "load-midpoint-data")
            return
        }

        let recommendationsValue: Result<MidpointRecommendationResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMidpointRecommendations(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
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
                    stationId: station.stationId,
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
                mapZoomLevel = 12
            } else if mapCenterCoordinate == nil {
                mapCenterCoordinate = averageCenterCoordinate()
                mapZoomLevel = 12
            }
        case let .failure(error):
            if loadError == nil {
                loadError = error.localizedDescription
            }
            recommendations = []
            if mapCenterCoordinate == nil {
                mapCenterCoordinate = averageCenterCoordinate()
                mapZoomLevel = 12
            }
        }

        isLoading = false
    }

    private func displayScoreText(_ score: Double?) -> String {
        guard let score, score > 0 else { return "-" }
        return String(format: "%.1f", score)
    }

    private func statusPriority(_ status: String) -> Int {
        switch status {
        case "PLACE_CONFIRMED": return 5
        case "MIDPOINT_CONFIRMED": return 4
        case "SELECTING_MIDPOINT": return 3
        case "ALL_LOCATIONS_SUBMITTED": return 2
        case "LOCATION_COLLECTING", "READY", "WAITING", "WAITING_ROOM", "WAITING_FOR_PARTICIPANTS", "RECRUITING", "CREATED", "": return 1
        default: return 0
        }
    }

    private func mergedPromiseStatus(existing: String, incoming: String) -> String {
        let normalizedIncoming = incoming.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedIncoming.isEmpty else { return existing }
        guard !existing.isEmpty else { return normalizedIncoming }
        return statusPriority(normalizedIncoming) >= statusPriority(existing) ? normalizedIncoming : existing
    }

    private func localizedCategory(_ raw: String?) -> String {
        guard let raw else { return "추천" }
        let lower = raw.lowercased()
        if lower.contains("cafe") || lower.contains("coffee") { return "카페" }
        if lower.contains("bar") || lower.contains("pub") || lower.contains("alcohol") { return "술집" }
        if lower.contains("restaurant") || lower.contains("food") || lower.contains("dining") { return "식당" }
        return raw
    }


    private func normalizedAIQueryText(_ raw: String) -> String {
        var normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = ["카페", "식당", "술집", "레스토랑", "음식점", "펍", "바"]
        for token in tokens {
            normalized = normalized.replacingOccurrences(
                of: #"(?<!\s)\#(token)"#,
                with: " " + token,
                options: .regularExpression
            )
        }
        normalized = normalized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func averageCenterCoordinate() -> CLLocationCoordinate2D? {
        let coords = participants.compactMap(\.coordinate)
        guard !coords.isEmpty else { return nil }
        let avgLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let avgLon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }

    private func focusMap(on coordinate: CLLocationCoordinate2D?) {
        guard let coordinate else { return }
        mapCenterCoordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude - 0.0075,
            longitude: coordinate.longitude
        )
        mapZoomLevel = 14
    }

    private func focusFinalPlaceMap(on coordinate: CLLocationCoordinate2D?) {
        guard let coordinate else { return }
        mapCenterCoordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude - 0.0028,
            longitude: coordinate.longitude
        )
        mapZoomLevel = 16
    }

    private func applyMapData(_ mapData: PromiseMapDataResponse) {
        if stage == .finalPlace,
           let firstRecommendationCoordinate = finalPlaceRecommendations.first?.coordinate {
            focusFinalPlaceMap(on: firstRecommendationCoordinate)
        } else if stage == .finalPlace,
                  let destination = mapData.destination,
                  let lat = destination.latitude,
                  let lon = destination.longitude {
            mapCenterCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            mapZoomLevel = 12
        } else if let midpoint = (mapData.recommendedMidpoints ?? []).first,
                  let lat = midpoint.latitude,
                  let lon = midpoint.longitude {
            mapCenterCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            mapZoomLevel = 12
        } else if mapCenterCoordinate == nil {
            mapCenterCoordinate = averageCenterCoordinate()
            mapZoomLevel = 12
        }
    }

    @MainActor
    func refreshMapDataForCurrentStage(accessToken: String, tokenType: String) async {
        let result: Result<PromiseMapDataResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMapData(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        if case let .success(mapData) = result {
            applyMapData(mapData)
        }
    }

    private func connectStatusSocketIfPossible() {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else { return }
        let tokenType = userSession.backendTokenType ?? "Bearer"
        promiseRealtime.connect(
            promiseId: promiseId,
            accessToken: accessToken,
            tokenType: tokenType,
            subscriptions: [.status]
        )
    }

    private func restartStatusPollingIfNeeded() {
        statusPollingTask?.cancel()
        statusPollingTask = nil

        guard !isCurrentUserHost else { return }

        let pollingStatuses: Set<String> = [
            "",
            "CREATED",
            "RECRUITING",
            "WAITING",
            "WAITING_ROOM",
            "WAITING_FOR_PARTICIPANTS",
            "READY",
            "LOCATION_COLLECTING",
            "SELECTING_MIDPOINT",
            "MIDPOINT_CONFIRMED"
        ]

        guard pollingStatuses.contains(currentPromiseStatus) else { return }

        statusPollingTask = Task {
            var lastObservedStatus = await MainActor.run { currentPromiseStatus }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { break }

                guard let nextStatus = await fetchCurrentPromiseStatus() else { continue }
                let mergedStatus = await MainActor.run {
                    mergedPromiseStatus(existing: currentPromiseStatus, incoming: nextStatus)
                }
                guard mergedStatus != lastObservedStatus else { continue }

                lastObservedStatus = mergedStatus

                await MainActor.run {
                    currentPromiseStatus = mergedStatus
                    print("[MidpointPolling] detected status change:", mergedStatus)
                }

                await loadMidpointData()

                if mergedStatus == "PLACE_CONFIRMED" {
                    break
                }
            }
        }
    }

    private func fetchCurrentPromiseStatus() async -> String? {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else { return nil }
        let tokenType = userSession.backendTokenType ?? "Bearer"

        let result: Result<PromiseStatusResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getPromiseStatus(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case let .success(response):
            return (response.status ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        case let .failure(error):
            print("[MidpointPolling] getPromiseStatus error:", error.localizedDescription)
            return nil
        }
    }

    private func returnHomeFromTopBar() {
        NotificationCenter.default.post(name: Notification.Name("waitingRoomShouldReturnHome"), object: nil)
        dismiss()
    }

    @MainActor
    private func returnHomeImmediatelyAfterPlaceConfirmed(source: String) {
        guard !hasTriggeredReturnHome else { return }
        hasTriggeredReturnHome = true

        print("[Midpoint] returning home after place confirmation from:", source)
        statusPollingTask?.cancel()
        statusPollingTask = nil
        promiseRealtime.disconnect()

        NotificationCenter.default.post(name: Notification.Name("closeWaitingRoomFlow"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("waitingRoomShouldReturnHome"), object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            dismiss()
        }
    }

    @MainActor
    private func handleStatusEvent(_ event: PromiseStatusSocketEvent) async {
        print("[MidpointRealtime] received status type:", event.type)
        if let newStatus = event.payload?.newStatus {
            currentPromiseStatus = mergedPromiseStatus(existing: currentPromiseStatus, incoming: newStatus)
        }

        restartStatusPollingIfNeeded()

        switch event.type {
        case "ALL_LOCATIONS_SUBMITTED":
            await loadMidpointData()
        case "MIDPOINT_CONFIRMED":
            await loadMidpointData()
        case "PLACE_CONFIRMED":
            returnHomeImmediatelyAfterPlaceConfirmed(source: "status-event")
        default:
            break
        }
    }

    @MainActor
    private func confirmRecommendedMidpoint(_ item: PlaceItem) async {
        guard !isSubmittingSelection else { return }
        guard let stationId = item.stationId else {
            actionMessage = "확정할 수 있는 역 정보가 없어요."
            isShowingActionAlert = true
            return
        }
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            actionMessage = "로그인 정보가 없습니다."
            isShowingActionAlert = true
            return
        }

        isSubmittingSelection = true
        let tokenType = userSession.backendTokenType ?? "Bearer"

        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.confirmMidpoint(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType,
                stationId: stationId
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .success:
            selectedMidpointTitle = item.title
            currentMidpointFallbackTitle = item.title
            cacheMidpointTitleIfPossible(item.title)
            selectedAIQuery = nil
            await loadFinalPlaceRecommendations(tab: selectedPlaceTab, query: nil)
        case let .failure(error):
            isSubmittingSelection = false
            actionMessage = error.localizedDescription
            isShowingActionAlert = true
        }
    }

    @MainActor
    private func requestFinalPlaceRecommendations(tab: PlaceCategoryTab, query: String? = nil) async -> Result<PlaceRecommendationResponse, Error> {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            return .failure(AuthAPIError.server(statusCode: 401, message: "로그인 정보가 없습니다."))
        }

        let tokenType = userSession.backendTokenType ?? "Bearer"
        let maxAttempts = 3
        for attempt in 1...maxAttempts {
            let result: Result<PlaceRecommendationResponse, Error> = await withCheckedContinuation { continuation in
                PromiseAPIClient.shared.getPlaceRecommendations(
                    promiseId: promiseId,
                    accessToken: accessToken,
                    tokenType: tokenType,
                    query: query,
                    tab: tab.rawValue
                ) { result in
                    continuation.resume(returning: result)
                }
            }

            switch result {
            case .success:
                return result
            case let .failure(error):
                if case let AuthAPIError.server(statusCode, _) = error, statusCode == 504, attempt < maxAttempts {
                    let delay = UInt64(attempt) * 600_000_000
                    try? await Task.sleep(nanoseconds: delay)
                    continue
                }
                return result
            }
        }

        return .failure(AuthAPIError.server(statusCode: 504, message: "장소 추천을 다시 불러오지 못했어요."))
    }

    @MainActor
    private func loadFinalPlaceRecommendations(tab: PlaceCategoryTab, query: String? = nil) async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            isSubmittingSelection = false
            actionMessage = "로그인 정보가 없습니다."
            isShowingActionAlert = true
            return
        }

        isLoading = true
        loadError = nil

        let tokenType = userSession.backendTokenType ?? "Bearer"
        let result = await requestFinalPlaceRecommendations(tab: tab, query: query)

        isLoading = false
        isSubmittingSelection = false

        switch result {
        case let .success(response):
            if (response.recommendations ?? []).isEmpty,
               let query,
               !query.isEmpty {
                let normalizedQuery = normalizedAIQueryText(query)
                if normalizedQuery != query {
                    await loadFinalPlaceRecommendations(tab: tab, query: normalizedQuery)
                    return
                }
            }

            finalPlaceRecommendations = (response.recommendations ?? []).map { place in
                let coordinate: CLLocationCoordinate2D?
                if let lat = place.latitude, let lon = place.longitude {
                    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                } else {
                    coordinate = nil
                }
                let distanceText: String
                if let distance = place.distance_from_midpoint {
                    let kilometers = max(0.01, distance / 1000.0)
                    distanceText = String(format: "%.2fkm", kilometers)
                } else {
                    distanceText = "-"
                }

                return FinalPlaceItem(
                    placeId: place.place_id,
                    title: place.place_name ?? "추천 장소",
                    address: place.address ?? "주소 정보 없음",
                    summary: place.ai_summary ?? "추천 장소",
                    imageURL: place.image_url,
                    scoreText: displayScoreText(place.ai_score),
                    walkTimeText: distanceText,
                    categoryText: localizedCategory(place.category),
                    coordinate: coordinate
                )
            }
            stage = .finalPlace
            let availableKeys = Set(finalPlaceRecommendations.map { finalPlaceSelectionKey(for: $0) })
            selectedFinalPlaceKeys.removeAll { !availableKeys.contains($0) }
            await refreshMapDataForCurrentStage(accessToken: accessToken, tokenType: tokenType)
            if let firstCoordinate = finalPlaceRecommendations.first?.coordinate {
                focusFinalPlaceMap(on: firstCoordinate)
            }
        case let .failure(error):
            actionMessage = error.localizedDescription
            isShowingActionAlert = true
        }
    }

    private func returnToMidpointSelection() {
        stage = .midpoint
        isSheetExpanded = false
        isShowingAIModal = false
        selectedPlaceTab = .all
        selectedAIQuery = nil
        aiPromptText = ""
        loadError = nil
        actionMessage = nil
        isShowingActionAlert = false
        isSubmittingSelection = false
        finalPlaceRecommendations = []
    }

    @MainActor
    private func changeMidpointSelection() async {
        guard isCurrentUserHost else {
            actionMessage = "중간지점 변경은 호스트만 할 수 있어요."
            isShowingActionAlert = true
            return
        }

        await resetMidpointSelection()
    }

    @MainActor
    private func loadMidpointRecommendationsForViewing() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            loadError = "로그인 정보가 없습니다."
            return
        }

        let tokenType = userSession.backendTokenType ?? "Bearer"
        isLoading = true
        loadError = nil

        let mapDataResult: Result<PromiseMapDataResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMapData(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch mapDataResult {
        case let .success(mapData):
            let midpointNameFromMapData = mapData.destination?.name ?? mapData.recommendedMidpoints?.first?.name
            currentMidpointFallbackTitle = midpointNameFromMapData ?? currentMidpointFallbackTitle
            cacheMidpointTitleIfPossible(midpointNameFromMapData)
            applyMapData(mapData)
        case .failure:
            break
        }

        let recommendationsValue: Result<MidpointRecommendationResponse, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMidpointRecommendations(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
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
                    stationId: station.stationId,
                    title: station.stationName ?? "추천 역",
                    subtitle: station.lineName ?? "노선 정보 없음",
                    timeText: "평균 \((station.averageTravelTimeMinutes ?? 0))분",
                    coordinate: coordinate
                )
            }

            if let stationName = normalizedDisplayTitle(response.recommendedStations?.first?.stationName) {
                currentMidpointFallbackTitle = stationName
                cacheMidpointTitleIfPossible(stationName)
            }

            if let midpoint = response.calculatedMidpoint,
               let lat = midpoint.latitude,
               let lon = midpoint.longitude {
                mapCenterCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                mapZoomLevel = 12
            } else if let firstCoordinate = recommendations.first?.coordinate {
                focusMap(on: firstCoordinate)
            }
            isLoading = false

        case let .failure(error):
            recommendations = []
            isLoading = false
            loadError = error.localizedDescription
        }
    }

    @MainActor
    private func requestAIRecommendations() async {
        let trimmed = aiPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalizedQuery = normalizedAIQueryText(trimmed)
        selectedAIQuery = normalizedQuery
        aiPromptText = normalizedQuery
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowingAIModal = false
        }
        await loadFinalPlaceRecommendations(tab: selectedPlaceTab, query: normalizedQuery)
    }

    @MainActor
    private func confirmSelectedFinalPlaces() async {
        guard let firstKey = selectedFinalPlaceKeys.first,
              let representative = finalPlaceRecommendations.first(where: { finalPlaceSelectionKey(for: $0) == firstKey }) else {
            actionMessage = "최종 확정할 장소를 먼저 선택해주세요."
            isShowingActionAlert = true
            return
        }

        await confirmFinalPlaceSelection(representative)
    }

    @MainActor
    private func confirmFinalPlaceSelection(_ item: FinalPlaceItem) async {
        guard !isSubmittingSelection else { return }
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            actionMessage = "로그인 정보가 없습니다."
            isShowingActionAlert = true
            return
        }
        guard let coordinate = item.coordinate else {
            actionMessage = "확정할 수 있는 장소 좌표가 없어요."
            isShowingActionAlert = true
            return
        }

        isSubmittingSelection = true
        let tokenType = userSession.backendTokenType ?? "Bearer"

        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.confirmFinalPlace(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType,
                placeId: item.placeId,
                placeName: item.title,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ) { result in
                continuation.resume(returning: result)
            }
        }

        isSubmittingSelection = false

        switch result {
        case .success:
            print("[Midpoint] final place confirmed. closing waiting room flow")
            returnHomeImmediatelyAfterPlaceConfirmed(source: "confirm-final-place-success")
        case let .failure(error):
            actionMessage = error.localizedDescription
            isShowingActionAlert = true
        }
    }

    @MainActor
    private func resetMidpointSelection() async {
        guard !isSubmittingSelection else { return }
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            actionMessage = "로그인 정보가 없습니다."
            isShowingActionAlert = true
            return
        }

        isSubmittingSelection = true
        let tokenType = userSession.backendTokenType ?? "Bearer"

        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.resetMidpoint(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: tokenType
            ) { result in
                continuation.resume(returning: result)
            }
        }

        isSubmittingSelection = false

        switch result {
        case .success:
            selectedPlaceTab = .all
            selectedAIQuery = nil
            selectedFinalPlaceKeys = []
            finalPlaceRecommendations = []
            currentPromiseStatus = "SELECTING_MIDPOINT"
            stage = .midpoint
            isSheetExpanded = false
            isShowingInfoCard = true
            scheduleInfoCardAutoHide()
            await loadMidpointData()
        case let .failure(error):
            actionMessage = error.localizedDescription
            isShowingActionAlert = true
        }
    }
}

private struct MarkerItem: Identifiable {
    let id = UUID()
    let userId: Int64?
    let title: String
    let icon: String
    let color: Color
    let coordinate: CLLocationCoordinate2D?
    let profileImageURL: String?
    let profileImageData: Data?
}

private struct PlaceItem: Identifiable {
    let id = UUID()
    let stationId: Int64?
    let title: String
    let subtitle: String
    let timeText: String
    let coordinate: CLLocationCoordinate2D?
}

private struct RecommendationLocationIcon: View {
    var body: some View {
        Image("RecommendationLocationBadge")
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 24, height: 24)
    }
}

private struct FinalPlaceItem: Identifiable {
    let id = UUID()
    let placeId: String?
    let title: String
    let address: String
    let summary: String
    let imageURL: String?
    let scoreText: String
    let walkTimeText: String
    let categoryText: String
    let coordinate: CLLocationCoordinate2D?
}

#if canImport(KakaoMapsSDK)
private struct KakaoMidpointMapView: UIViewRepresentable {
    @Binding var draw: Bool
    let centerCoordinate: CLLocationCoordinate2D?
    let zoomLevel: Int
    let participants: [MarkerItem]
    let recommendations: [PlaceItem]

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
        context.coordinator.latestZoomLevel = zoomLevel
        context.coordinator.latestParticipants = participants
        context.coordinator.latestRecommendations = recommendations

        let size = uiView.bounds.size
        if size.width > 10, size.height > 10 {
            context.coordinator.updateContainerSizeIfNeeded(size)
            context.coordinator.prepareIfNeeded()
        } else {
            print("[KakaoMap] updateUIView skipped, bounds too small: \(size)")
        }

        if draw {
            context.coordinator.requestMapActivation()
            context.coordinator.attachMapViewIfReady()
            context.coordinator.moveCameraIfPossible()
            context.coordinator.syncMarkersIfPossible()
        } else {
            context.coordinator.hasActivatedEngine = false
            context.coordinator.controller?.pauseEngine()
        }
    }

    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: Coordinator) {
        coordinator.hasActivatedEngine = false
        coordinator.controller?.pauseEngine()
        coordinator.controller?.resetEngine()
    }

    final class Coordinator: NSObject, MapControllerDelegate {
        var controller: KMController?
        var latestCoordinate: CLLocationCoordinate2D?
        var latestZoomLevel: Int = 7
        var latestParticipants: [MarkerItem] = []
        var latestRecommendations: [PlaceItem] = []
        var containerSize: CGSize = .zero

        private var hasPreparedEngine = false
        private var hasAuthenticated = false
        private var hasAddedMapView = false
        private var isAddingMapView = false
        var hasActivatedEngine = false
        private var lastCameraSignature: String?
        private var lastParticipantSignature: String?
        private var lastRecommendationSignature: String?
        private let participantLayerID = "midpoint_participants"
        private let recommendationLayerID = "midpoint_recommendations"
        private let recommendationStyleID = "midpoint_recommendation_style"
        private var registeredStyleIDs: Set<String> = []

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
            guard hasPreparedEngine else { return }
            guard hasAuthenticated else {
                print("[KakaoMap] addViews deferred: auth not finished")
                return
            }
            guard !hasAddedMapView else { return }
            guard !isAddingMapView else { return }

            guard Thread.isMainThread else {
                DispatchQueue.main.async { [weak self] in
                    self?.addViews()
                }
                return
            }

            guard let controller else { return }
            if controller.getView("midpoint_mapview") != nil {
                hasAddedMapView = true
                isAddingMapView = false
                return
            }

            isAddingMapView = true
            let defaultPosition = MapPoint(longitude: 127.0276, latitude: 37.4979)
            let mapviewInfo = MapviewInfo(
                viewName: "midpoint_mapview",
                viewInfoName: "map",
                defaultPosition: defaultPosition,
                defaultLevel: 7
            )
            let size = containerSize == .zero ? CGSize(width: 393, height: 852) : containerSize
            DispatchQueue.main.async { [weak self] in
                guard let self, let controller = self.controller else { return }
                controller.addView(mapviewInfo, viewSize: size)
            }
            print("[KakaoMap] addViews with size: \(size)")
            print("[KakaoMap] controller state after addViews: \(controller.getStateDescMessage())")
        }

        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            isAddingMapView = false
            hasAddedMapView = true
            print("[KakaoMap] addViewSucceeded: \(viewName) / \(viewInfoName)")
            guard let mapView = controller?.getView("midpoint_mapview") as? KakaoMap else { return }
            if containerSize != .zero {
                mapView.viewRect = CGRect(origin: .zero, size: containerSize)
            }
            requestMapActivation()
            moveCameraIfPossible()
            syncMarkersIfPossible()
        }

        func addViewFailed(_ viewName: String, viewInfoName: String) {
            isAddingMapView = false
            hasAddedMapView = false
            print("[KakaoMap] addViewFailed: \(viewName) / \(viewInfoName)")
        }

        func authenticationSucceeded() {
            hasAuthenticated = true
            DispatchQueue.main.async { [weak self] in
                self?.attachMapViewIfReady()
            }
            print("[KakaoMap] authenticationSucceeded")
            print("[KakaoMap] controller state on auth success: \(controller?.getStateDescMessage() ?? "unknown")")
        }

        func authenticationFailed(_ errorCode: Int, desc: String) {
            print("[KakaoMap] authenticationFailed: \(errorCode) - \(desc)")
        }

        func containerDidResized(_ size: CGSize) {
            containerSize = size
            print("[KakaoMap] containerDidResized: \(size)")
            attachMapViewIfReady()
            guard let mapView = controller?.getView("midpoint_mapview") as? KakaoMap else { return }
            mapView.viewRect = CGRect(origin: .zero, size: size)
            requestMapActivation()
            moveCameraIfPossible()
            syncMarkersIfPossible()
        }

        func attachMapViewIfReady() {
            guard hasPreparedEngine else { return }
            guard hasAuthenticated else { return }
            guard containerSize.width > 10, containerSize.height > 10 else { return }
            addViews()
        }

        func requestMapActivation() {
            guard let controller else { return }
            guard hasPreparedEngine else {
                print("[KakaoMap] activation deferred: engine not prepared")
                return
            }
            guard !hasActivatedEngine else { return }
            hasActivatedEngine = true
            controller.activateEngine()
            print("[KakaoMap] activateEngine called")
            print("[KakaoMap] controller state after activate: \(controller.getStateDescMessage())")
        }

        func moveCameraIfPossible() {
            guard let mapView = controller?.getView("midpoint_mapview") as? KakaoMap else { return }
            let coordinate = latestCoordinate ?? CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
            let signature = String(format: "%.6f:%.6f:%d", coordinate.latitude, coordinate.longitude, latestZoomLevel)
            guard lastCameraSignature != signature else { return }
            lastCameraSignature = signature
            let target = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
            let cameraUpdate = CameraUpdate.make(target: target, zoomLevel: latestZoomLevel, mapView: mapView)
            mapView.moveCamera(cameraUpdate)
            print("[KakaoMap] moveCamera to: \(coordinate.latitude), \(coordinate.longitude)")
        }

        func syncMarkersIfPossible() {
            guard let mapView = controller?.getView("midpoint_mapview") as? KakaoMap else { return }

            let participantSignature = latestParticipants.map {
                let coordinateText = $0.coordinate.map { String(format: "%.6f:%.6f", $0.latitude, $0.longitude) } ?? "nil"
                return "\($0.userId ?? -1):\(coordinateText):\($0.profileImageURL ?? "")"
            }.joined(separator: "|")
            let recommendationSignature = latestRecommendations.map {
                let coordinateText = $0.coordinate.map { String(format: "%.6f:%.6f", $0.latitude, $0.longitude) } ?? "nil"
                return "\($0.stationId ?? -1):\(coordinateText)"
            }.joined(separator: "|")
            guard participantSignature != lastParticipantSignature || recommendationSignature != lastRecommendationSignature else {
                return
            }
            lastParticipantSignature = participantSignature
            lastRecommendationSignature = recommendationSignature

            let labelManager = mapView.getLabelManager()
            guard let participantLayer = ensureLabelLayer(
                labelManager,
                layerID: participantLayerID,
                zOrder: 30
            ), let recommendationLayer = ensureLabelLayer(
                labelManager,
                layerID: recommendationLayerID,
                zOrder: 10
            ) else {
                return
            }

            participantLayer.visible = true
            recommendationLayer.visible = true
            participantLayer.setClickable(false)
            recommendationLayer.setClickable(false)
            participantLayer.clearAllItems()
            recommendationLayer.clearAllItems()

            registerRecommendationStyleIfNeeded(labelManager)

            for item in latestParticipants {
                guard let coordinate = item.coordinate else { continue }
                let styleID = participantStyleID(for: item)
                registerParticipantStyleIfNeeded(labelManager, item: item, styleID: styleID)

                let options = PoiOptions(styleID: styleID, poiID: item.id.uuidString)
                options.rank = 1
                options.clickable = false
                options.addText(PoiText(text: item.title, styleIndex: 0))

                let poi = participantLayer.addPoi(
                    option: options,
                    at: MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
                )
                poi?.show()
            }

            for item in latestRecommendations {
                guard let coordinate = item.coordinate else { continue }
                let options = PoiOptions(styleID: recommendationStyleID, poiID: item.id.uuidString)
                options.rank = 0
                options.clickable = false

                let poi = recommendationLayer.addPoi(
                    option: options,
                    at: MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)
                )
                poi?.show()
            }

            participantLayer.showAllPois()
            recommendationLayer.showAllPois()
            mapView.refresh()
            print("[KakaoMap] synced markers - participants: \(latestParticipants.count), recommendations: \(latestRecommendations.count)")
        }

        private func ensureLabelLayer(_ labelManager: LabelManager, layerID: String, zOrder: Int) -> LabelLayer? {
            if let layer = labelManager.getLabelLayer(layerID: layerID) {
                return layer
            }

            let options = LabelLayerOptions(
                layerID: layerID,
                competitionType: .none,
                competitionUnit: .symbolFirst,
                orderType: .rank,
                zOrder: zOrder
            )
            return labelManager.addLabelLayer(option: options)
        }

        private func participantStyleID(for item: MarkerItem) -> String {
            let identity = item.userId.map { "id_\($0)" } ?? item.title.replacingOccurrences(of: " ", with: "_")
            let hasProfile = item.profileImageData != nil || item.profileImageURL != nil
            return "participant_\(identity)_\(hasProfile ? "profile" : "placeholder")"
        }

        private func registerParticipantStyleIfNeeded(_ labelManager: LabelManager, item: MarkerItem, styleID: String) {
            guard !registeredStyleIDs.contains(styleID) else { return }

            let iconStyle = PoiIconStyle(
                symbol: makeParticipantMarkerImage(item: item),
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            )
            let textStyle = TextStyle(
                fontSize: 22,
                fontColor: UIColor(red: 0.07, green: 0.09, blue: 0.16, alpha: 1),
                strokeThickness: 4,
                strokeColor: .white
            )
            let lineStyle = PoiTextLineStyle(textStyle: textStyle)
            let poiTextStyle = PoiTextStyle(textLineStyles: [lineStyle])
            let perLevelStyle = PerLevelPoiStyle(
                iconStyle: iconStyle,
                textStyle: poiTextStyle,
                padding: 8,
                level: 0
            )
            labelManager.addPoiStyle(PoiStyle(styleID: styleID, styles: [perLevelStyle]))
            registeredStyleIDs.insert(styleID)
        }

        private func registerRecommendationStyleIfNeeded(_ labelManager: LabelManager) {
            guard !registeredStyleIDs.contains(recommendationStyleID) else { return }

            let iconStyle = PoiIconStyle(
                symbol: makeCircularSymbolImage(
                    fill: UIColor(red: 0.22, green: 0.62, blue: 0.96, alpha: 1),
                    systemName: "mappin.circle.fill",
                    size: CGSize(width: 54, height: 54),
                    symbolPointSize: 14
                ),
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            )
            let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, padding: 0, level: 0)
            labelManager.addPoiStyle(PoiStyle(styleID: recommendationStyleID, styles: [perLevelStyle]))
            registeredStyleIDs.insert(recommendationStyleID)
        }

        private func makeParticipantMarkerImage(item: MarkerItem) -> UIImage? {
            if let data = item.profileImageData,
               let image = UIImage(data: data),
               let normalizedImage = normalizedMarkerSourceImage(from: image) {
                return circularAvatarImage(from: normalizedImage, tint: UIColor(item.color))
            }
            return makeAvatarPlaceholderImage(
                fill: UIColor(item.color),
                systemName: item.icon,
                size: CGSize(width: 54, height: 54),
                symbolPointSize: 18
            )
        }

        private func circularAvatarImage(from image: UIImage, tint: UIColor) -> UIImage? {
            let size = CGSize(width: 54, height: 54)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()
            image.draw(in: rect)
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
                let iconWidth: CGFloat = 16.3
                let iconHeight: CGFloat = 19.3
                let symbolRect = CGRect(
                    x: (size.width - iconWidth) / 2,
                    y: (size.height - iconHeight) / 2,
                    width: iconWidth,
                    height: iconHeight
                )
                context.saveGState()
                context.translateBy(x: symbolRect.midX, y: symbolRect.midY)
                context.rotate(by: .pi)
                iconImage.draw(in: CGRect(x: -iconWidth / 2, y: -iconHeight / 2, width: iconWidth, height: iconHeight))
                context.restoreGState()
            }
            guard let rendered = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
            return normalizedMarkerSourceImage(from: rendered) ?? rendered
        }

        private func normalizedMarkerSourceImage(from image: UIImage) -> UIImage? {
            let targetWidth = max(Int(ceil(image.size.width)), 1)
            let targetHeight = max(Int(ceil(image.size.height)), 1)
            guard let sourceCGImage = image.cgImage,
                  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return image }
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            guard let context = CGContext(
                data: nil,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: targetWidth * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return image
            }

            context.interpolationQuality = .high
            context.translateBy(x: 0, y: CGFloat(targetHeight))
            context.scaleBy(x: 1, y: -1)
            context.draw(sourceCGImage, in: CGRect(x: 0, y: 0, width: CGFloat(targetWidth), height: CGFloat(targetHeight)))

            guard let cgImage = context.makeImage() else { return image }
            return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
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
            DispatchQueue.main.async {
                manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestCoordinate = locations.last?.coordinate
        DispatchQueue.main.async { [weak self] in
            self?.coordinate = latestCoordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[KakaoMap] location error: \(error.localizedDescription)")
    }
}
