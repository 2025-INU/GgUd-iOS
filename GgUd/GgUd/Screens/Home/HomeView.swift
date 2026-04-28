import SwiftUI

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
    }

    private var currentItems: [HomePromise] {
        selectedSegment == .ongoing ? ongoing : scheduled
    }

    private var emptyMessage: String {
        selectedSegment == .ongoing ? "진행중인 약속이 없습니다." : "예정된 약속이 없습니다."
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
