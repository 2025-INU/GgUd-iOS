//
//  DepartureSetupView.swift
//  GgUd
//
//

import SwiftUI
import CoreLocation

struct DepartureSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTransport: TransportOption? = nil
    @State private var selectedLocation: String? = nil
    @State private var addressText: String = ""
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationAlert: Bool = false
    @State private var locationAlertMessage: String = ""
    @State private var navigateToWaitingRoom: Bool = false

    private let transports: [TransportOption] = [
        .init(title: "도보", systemImage: "figure.walk", color: Color(red: 0.22, green: 0.80, blue: 0.44)),
        .init(title: "버스", systemImage: "bus", color: Color(red: 0.28, green: 0.55, blue: 0.98)),
        .init(title: "지하철", systemImage: "tram", color: Color(red: 0.64, green: 0.44, blue: 0.96)),
        .init(title: "자동차", systemImage: "car", color: Color(red: 0.98, green: 0.36, blue: 0.35)),
        .init(title: "택시", systemImage: "car.fill", color: Color(red: 0.97, green: 0.78, blue: 0.07)),
        .init(title: "자전거", systemImage: "bicycle", color: Color(red: 0.99, green: 0.57, blue: 0.20))
    ]

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

                        Text("교통수단")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .padding(.top, 8)

                        transportGrid

                        Button(action: { navigateToWaitingRoom = true }) {
                            Text("약속 참여하기")
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
                            destination: WaitingRoomView(),
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
        .onChange(of: locationManager.address) { newValue in
            guard let newValue else { return }
            selectedLocation = newValue
            addressText = newValue
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
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text("약속 참여")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .padding(.leading, 24)
        .padding(.top, 16)
        .padding(.bottom, 17)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
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
                    Text("대학 동기 모임")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    Text("2024-12-15 · 19:00")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.subText)

                    Text("주최자: 김민수")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppColors.subText)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)

                Text("출발 위치와 교통수단을 선택해주세요")
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
        selectedLocation != nil && selectedTransport != nil
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
    }

    private var transportGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            ForEach(transports) { item in
                transportCell(item)
            }
        }
    }

    private func transportCell(_ item: TransportOption) -> some View {
        Button {
            selectedTransport = item
        } label: {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(item.color)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: item.systemImage)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    )

                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selectedTransport?.id == item.id ? AppColors.primary : AppColors.border, lineWidth: selectedTransport?.id == item.id ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct TransportOption: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let systemImage: String
    let color: Color
}

private final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var address: String? = nil
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
    DepartureSetupView()
}
