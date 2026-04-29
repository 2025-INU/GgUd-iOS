//
//  DepartureSetupView.swift
//  GgUd
//
//

import SwiftUI
import CoreLocation
import Combine

struct DepartureSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64

        @State private var selectedLocation: String? = nil
    @State private var addressText: String = ""
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationAlert: Bool = false
    @State private var locationAlertMessage: String = ""
    @State private var navigateToWaitingRoom: Bool = false
    @State private var isSubmitting = false
    @State private var summary: PromiseSummaryResponse?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        summaryCard

                        Text("출발 위치")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        currentLocationButton

                        if let selectedLocation {
                            selectedLocationPill(text: selectedLocation)
                        }

                        searchField


                        Button(action: submitDeparture) {
                            Text("약속 참여하기")
                                .overlay {
                                    if isSubmitting {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(canJoin ? Color.white : Color.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: canJoin
                                        ? [Color(red: 0.07, green: 0.65, blue: 0.96),
                                           Color(red: 0.16, green: 0.40, blue: 0.95)]
                                        : [Color(red: 0.55, green: 0.80, blue: 0.98),
                                           Color(red: 0.52, green: 0.67, blue: 0.95)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(canJoin ? 0.12 : 0.06), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        .disabled(!canJoin)

                        NavigationLink(
                            destination: WaitingRoomView(promiseId: promiseId),
                            isActive: $navigateToWaitingRoom
                        ) {
                            EmptyView()
                        }
                        .hidden()

                        Text("참여하면 약속 대기방으로 이동합니다")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(AppColors.subText)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task(id: promiseId) {
            await loadSummary()
        }
        .onChange(of: locationManager.address) { newValue in
            guard let newValue else { return }
            selectedLocation = newValue
            addressText = newValue
        }
        .onReceive(locationManager.$coordinate) { newValue in
            guard let newValue else { return }
            selectedCoordinate = newValue
        }
        .onChange(of: locationManager.errorMessage) { newValue in
            guard let newValue else { return }
            locationAlertMessage = newValue
            showLocationAlert = true
        }
        .alert("위치 설정", isPresented: $showLocationAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(locationAlertMessage)
        }
    }

    private var topBar: some View {
        AppBar(title: "약속 참여", onBack: { dismiss() })
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.30, green: 0.70, blue: 1.0),
                                 Color(red: 0.22, green: 0.56, blue: 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(summary?.title ?? "약속 불러오는 중")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    Text(summaryDateTimeText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.subText)

                    Text("주최자: \(summary?.hostNickname ?? "-")")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppColors.subText)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Text("출발 위치를 선택해주세요")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(20)
        .background(Color(red: 0.94, green: 0.97, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var canJoin: Bool {
        selectedLocation != nil
    }

    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil

    private var summaryDateTimeText: String {
        guard let dateString = summary?.promiseDateTime,
              let date = DepartureDateFormatter.parse(dateString)
        else { return "- · --:--" }
        return "\(DepartureDateFormatter.date.string(from: date)) · \(DepartureDateFormatter.time.string(from: date))"
    }

    private var currentLocationButton: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.circle")
                .font(.system(size: 18, weight: .semibold))
            Text("현재 위치로 설정")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(AppColors.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color(red: 0.93, green: 0.97, blue: 1.0))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.65, green: 0.82, blue: 0.98), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            addressText = "현재 위치를 가져오는 중..."
            selectedLocation = addressText
            locationManager.requestLocation()
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.subText)
            TextField("주소를 검색하세요", text: $addressText)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.text)
                .onChange(of: addressText) { newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    selectedLocation = trimmed.isEmpty ? nil : trimmed
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func selectedLocationPill(text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.45, blue: 0.24))
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(red: 0.90, green: 0.98, blue: 0.93))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.62, green: 0.90, blue: 0.72), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @MainActor
    private func loadSummary() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else { return }

        await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getPromiseSummary(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer"
            ) { result in
                DispatchQueue.main.async {
                    if case let .success(summary) = result {
                        self.summary = summary
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func friendlyLocationErrorMessage(_ error: Error) -> String {
        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                return "현재 위치를 아직 찾지 못했어요. 시뮬레이터라면 Features > Location에서 위치를 먼저 설정한 뒤 다시 시도해주세요."
            case .denied:
                return "위치 권한이 꺼져 있어요. 설정에서 위치 권한을 허용한 뒤 다시 시도해주세요."
            case .network:
                return "네트워크 문제로 위치를 가져오지 못했어요. 잠시 후 다시 시도해주세요."
            default:
                return "위치 정보를 가져오지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }

        if let geocodeError = error as? CLError, geocodeError.code == .geocodeFoundNoResult {
            return "입력한 주소를 찾지 못했어요. 주소를 조금 더 자세히 입력해주세요."
        }

        let nsError = error as NSError
        if nsError.domain == kCLErrorDomain && nsError.code == CLError.locationUnknown.rawValue {
            return "현재 위치를 아직 찾지 못했어요. 시뮬레이터라면 Features > Location에서 위치를 먼저 설정한 뒤 다시 시도해주세요."
        }

        return "위치 정보를 처리하지 못했어요. 잠시 후 다시 시도해주세요."
    }

    private func submitDeparture() {
        guard canJoin else { return }
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            locationAlertMessage = "로그인 정보가 없습니다. 다시 로그인해주세요."
            showLocationAlert = true
            return
        }

        isSubmitting = true

        let finishSubmission: (Result<(Double, Double, String?), Error>) -> Void = { result in
            switch result {
            case let .success((latitude, longitude, address)):
                PromiseAPIClient.shared.updateDeparture(
                    promiseId: promiseId,
                    accessToken: accessToken,
                    tokenType: userSession.backendTokenType ?? "Bearer",
                    latitude: latitude,
                    longitude: longitude,
                    address: address
                ) { apiResult in
                    DispatchQueue.main.async {
                        isSubmitting = false
                        switch apiResult {
                        case .success:
                            navigateToWaitingRoom = true
                        case let .failure(error):
                            locationAlertMessage = friendlyLocationErrorMessage(error)
                            showLocationAlert = true
                        }
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    isSubmitting = false
                    locationAlertMessage = friendlyLocationErrorMessage(error)
                    showLocationAlert = true
                }
            }
        }

        if let selectedCoordinate {
            finishSubmission(.success((selectedCoordinate.latitude, selectedCoordinate.longitude, selectedLocation)))
            return
        }

        let trimmedAddress = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            isSubmitting = false
            locationAlertMessage = "출발 위치를 입력해주세요."
            showLocationAlert = true
            return
        }

        CLGeocoder().geocodeAddressString(trimmedAddress) { placemarks, error in
            if let error {
                finishSubmission(.failure(error))
                return
            }

            guard let coordinate = placemarks?.first?.location?.coordinate else {
                finishSubmission(.failure(AuthAPIError.server(statusCode: 0, message: "주소를 좌표로 변환하지 못했습니다.")))
                return
            }

            finishSubmission(.success((coordinate.latitude, coordinate.longitude, trimmedAddress)))
        }
    }
}

private enum DepartureDateFormatter {
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

    static let isoWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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
        isoWithFractional.date(from: string)
        ?? ISO8601DateFormatter().date(from: string)
        ?? localDateTime.date(from: string)
    }
}

private final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var address: String? = nil
    @Published var coordinate: CLLocationCoordinate2D? = nil
    @Published var errorMessage: String? = nil

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            errorMessage = "위치 권한을 허용해주세요."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        coordinate = location.coordinate
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            if let placemark = placemarks?.first {
                let parts = [placemark.administrativeArea,
                             placemark.locality,
                             placemark.subLocality,
                             placemark.name]
                    .compactMap { $0 }
                self.address = parts.joined(separator: " ")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "현재 위치를 가져오지 못했습니다. 잠시 후 다시 시도해주세요."
    }
}

#Preview {
    DepartureSetupView(promiseId: 1)
}
