import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var userSession: UserSessionStore
    @State private var showSearchBar = false
    @State private var keyword = ""
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var items: [HistoryItem] = []

    private var filteredItems: [HistoryItem] {
        let q = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(q) || $0.location.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            historyHeader

            Divider()
                .overlay(Color(hex: "#E5E7EB"))

            Spacer().frame(height: 11)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if isLoading {
                        Text("불러오는 중...")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "#6B7280"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let loadError {
                        Text(loadError)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "#6B7280"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if filteredItems.isEmpty {
                        Text("표시할 히스토리가 없습니다.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "#6B7280"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(filteredItems) { item in
                            HistoryCard(item: item)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 106)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.2), value: showSearchBar)
        .task(id: userSession.backendAccessToken) {
            await loadHistory()
        }
    }

    private var historyHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("약속 히스토리")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(hex: "#111827"))

                Spacer()

                Button {
                    let next = !showSearchBar
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearchBar = next
                    }
                    if !next { keyword = "" }
                } label: {
                    Group {
                        if showSearchBar {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color(hex: "#4B5563"))
                                .frame(width: 24, height: 24)
                        } else {
                            SearchIcon()
                                .frame(width: 20, height: 20)
                        }
                    }
                    .frame(width: 37, height: 44)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 76)
            .padding(.horizontal, 24)

            if showSearchBar {
                HStack(spacing: 18) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#9CA3AF"))
                        .frame(width: 12, height: 12)

                    TextField("약속 이름이나 친구 이름을 검색하세요", text: $keyword)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#111827"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .onChange(of: keyword) { _, newValue in
                            if newValue.count > 50 {
                                keyword = String(newValue.prefix(50))
                            }
                        }
                }
                .padding(.horizontal, 17)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#F9FAFB"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    @MainActor
    private func loadHistory() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            items = []
            loadError = "로그인이 필요합니다."
            return
        }

        isLoading = true
        loadError = nil

        await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getMyPromises(
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer",
                page: 0,
                size: 100
            ) { result in
                DispatchQueue.main.async {
                    isLoading = false

                    switch result {
                    case let .success(promises):
                        items = promises
                            .filter { promise in
                                let status = (promise.status ?? "").uppercased()
                                return status != "CANCELED" && status != "CANCELLED"
                            }
                            .map(HistoryItem.init)
                        loadError = nil
                    case .failure:
                        items = []
                        loadError = "히스토리를 불러오지 못했습니다."
                    }

                    continuation.resume()
                }
            }
        }
    }
}

private struct SearchIcon: View {
    var body: some View {
        SearchIconShape()
            .fill(Color(hex: "#4B5563"))
            .accessibilityHidden(true)
    }
}

private struct SearchIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 13.3733, y: 12.1833))
        path.addLine(to: CGPoint(x: 16.9418, y: 15.75))
        path.addLine(to: CGPoint(x: 15.7579, y: 16.9333))
        path.addLine(to: CGPoint(x: 12.1894, y: 13.3667))
        path.addCurve(to: CGPoint(x: 10.0383, y: 14.5667),
                      control1: CGPoint(x: 11.5335, y: 13.8889),
                      control2: CGPoint(x: 10.8165, y: 14.2889))
        path.addCurve(to: CGPoint(x: 7.50375, y: 15),
                      control1: CGPoint(x: 9.21572, y: 14.8556),
                      control2: CGPoint(x: 8.37085, y: 15))
        path.addCurve(to: CGPoint(x: 3.71852, y: 13.9833),
                      control1: CGPoint(x: 6.14752, y: 15),
                      control2: CGPoint(x: 4.88577, y: 14.6611))
        path.addCurve(to: CGPoint(x: 1.03385, y: 11.2833),
                      control1: CGPoint(x: 2.58462, y: 13.3167),
                      control2: CGPoint(x: 1.68973, y: 12.4167))
        path.addCurve(to: CGPoint(x: 0, y: 7.5),
                      control1: CGPoint(x: 0.344617, y: 10.1167),
                      control2: CGPoint(x: 0, y: 8.85556))
        path.addCurve(to: CGPoint(x: 1.03385, y: 3.71667),
                      control1: CGPoint(x: 0, y: 6.14444),
                      control2: CGPoint(x: 0.344617, y: 4.88333))
        path.addCurve(to: CGPoint(x: 3.71852, y: 1.03333),
                      control1: CGPoint(x: 1.68973, y: 2.58333),
                      control2: CGPoint(x: 2.58462, y: 1.68889))
        path.addCurve(to: CGPoint(x: 7.50375, y: 0),
                      control1: CGPoint(x: 4.88577, y: 0.344444),
                      control2: CGPoint(x: 6.14752, y: 0))
        path.addCurve(to: CGPoint(x: 11.289, y: 1.03333),
                      control1: CGPoint(x: 8.85998, y: 0),
                      control2: CGPoint(x: 10.1217, y: 0.344444))
        path.addCurve(to: CGPoint(x: 13.9903, y: 3.71667),
                      control1: CGPoint(x: 12.4229, y: 1.68889),
                      control2: CGPoint(x: 13.3233, y: 2.58333))
        path.addCurve(to: CGPoint(x: 15.0075, y: 7.5),
                      control1: CGPoint(x: 14.6684, y: 4.88333),
                      control2: CGPoint(x: 15.0075, y: 6.14444))
        path.addCurve(to: CGPoint(x: 14.5739, y: 10.0333),
                      control1: CGPoint(x: 15.0075, y: 8.36667),
                      control2: CGPoint(x: 14.863, y: 9.21111))
        path.addCurve(to: CGPoint(x: 13.3733, y: 12.1833),
                      control1: CGPoint(x: 14.296, y: 10.8111),
                      control2: CGPoint(x: 13.8958, y: 11.5278))

        path.move(to: CGPoint(x: 11.6892, y: 11.5667))
        path.addCurve(to: CGPoint(x: 12.9064, y: 9.73333),
                      control1: CGPoint(x: 12.2117, y: 11.0333),
                      control2: CGPoint(x: 12.6174, y: 10.4222))
        path.addCurve(to: CGPoint(x: 13.34, y: 7.5),
                      control1: CGPoint(x: 13.1955, y: 9.02222),
                      control2: CGPoint(x: 13.34, y: 8.27778))
        path.addCurve(to: CGPoint(x: 12.5396, y: 4.55),
                      control1: CGPoint(x: 13.34, y: 6.44444),
                      control2: CGPoint(x: 13.0732, y: 5.46111))
        path.addCurve(to: CGPoint(x: 10.4552, y: 2.46667),
                      control1: CGPoint(x: 12.0282, y: 3.67222),
                      control2: CGPoint(x: 11.3334, y: 2.97778))
        path.addCurve(to: CGPoint(x: 7.50375, y: 1.66667),
                      control1: CGPoint(x: 9.54366, y: 1.93333),
                      control2: CGPoint(x: 8.55983, y: 1.66667))
        path.addCurve(to: CGPoint(x: 4.55227, y: 2.46667),
                      control1: CGPoint(x: 6.44767, y: 1.66667),
                      control2: CGPoint(x: 5.46384, y: 1.93333))
        path.addCurve(to: CGPoint(x: 2.4679, y: 4.55),
                      control1: CGPoint(x: 3.67406, y: 2.97778),
                      control2: CGPoint(x: 2.97927, y: 3.67222))
        path.addCurve(to: CGPoint(x: 1.6675, y: 7.5),
                      control1: CGPoint(x: 1.9343, y: 5.46111),
                      control2: CGPoint(x: 1.6675, y: 6.44444))
        path.addCurve(to: CGPoint(x: 2.4679, y: 10.45),
                      control1: CGPoint(x: 1.6675, y: 8.55556),
                      control2: CGPoint(x: 1.9343, y: 9.53889))
        path.addCurve(to: CGPoint(x: 4.55227, y: 12.5333),
                      control1: CGPoint(x: 2.97927, y: 11.3278),
                      control2: CGPoint(x: 3.67406, y: 12.0222))
        path.addCurve(to: CGPoint(x: 7.50375, y: 13.3333),
                      control1: CGPoint(x: 5.46384, y: 13.0667),
                      control2: CGPoint(x: 6.44767, y: 13.3333))
        path.addCurve(to: CGPoint(x: 9.7382, y: 12.9),
                      control1: CGPoint(x: 8.28192, y: 13.3333),
                      control2: CGPoint(x: 9.02673, y: 13.1889))
        path.addCurve(to: CGPoint(x: 11.5724, y: 11.6833),
                      control1: CGPoint(x: 10.4274, y: 12.6111),
                      control2: CGPoint(x: 11.0388, y: 12.2056))
        path.addLine(to: CGPoint(x: 11.6892, y: 11.5667))

        let scaleX = rect.width / 17.0
        let scaleY = rect.height / 17.0
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

#Preview {
    HistoryView()
        .environmentObject(UserSessionStore())
}

private extension HistoryItem {
    init(_ promise: BackendPromise) {
        self.init(
            title: promise.title ?? "제목 없음",
            dateText: HistoryDateFormatter.dateText(from: promise.promiseDateTime),
            timeText: HistoryDateFormatter.timeText(from: promise.promiseDateTime),
            memberCount: max(1, Int(promise.participantCount ?? 1)),
            location: promise.confirmedPlaceName ?? "장소 미정",
            status: .done
        )
    }
}

private enum HistoryDateFormatter {
    static func parsedDate(from value: String?) -> Date? {
        guard let value else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) { return date }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: value) { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: value)
    }

    static func dateText(from value: String?) -> String {
        guard let date = parsedDate(from: value) else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }

    static func timeText(from value: String?) -> String {
        guard let date = parsedDate(from: value) else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}
