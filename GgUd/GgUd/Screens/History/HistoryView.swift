//
//  HistoryView.swift
//  GgUd
//
//

import SwiftUI

struct HistoryView: View {
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""

    private let items: [HistoryItem] = [
        .init(title: "친구들과 카페 모임", dateText: "2024년 1월 10일", timeText: "오후 3:00", memberCount: 4, extraCount: 0, location: "홍대 스타벅스", status: .done),
        .init(title: "회사 동료 저녁식사", dateText: "2024년 1월 8일", timeText: "오후 7:30", memberCount: 6, extraCount: 2, location: "강남역 맛집", status: .done),
        .init(title: "가족 모임", dateText: "2024년 1월 5일", timeText: "오후 12:00", memberCount: 8, extraCount: 4, location: "집", status: .done),
        .init(title: "동창회", dateText: "2024년 1월 3일", timeText: "오후 6:00", memberCount: 12, extraCount: 8, location: "신촌 음식점", status: .canceled),
        .init(title: "영화 관람", dateText: "2023년 12월 28일", timeText: "오후 8:00", memberCount: 3, extraCount: 0, location: "CGV 강남", status: .done)
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HistoryTopBar(showSearch: $showSearch, searchText: $searchText)
                    if showSearch {
                        HistorySearchBar(text: $searchText)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                            .background(Color.white)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(items) { item in
                            HistoryCard(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        
        .animation(.easeInOut(duration: 0.2), value: showSearch)
    }
}


private struct HistoryTopBar: View {
    @Binding var showSearch: Bool
    @Binding var searchText: String

    var body: some View {
        HStack {
            Text("약속 히스토리")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)

            Spacer()

            if showSearch {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearch = false
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.subText)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearch = true
                    }
                }) {
                    SearchIcon()
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .padding(.leading, 24)
        .padding(.trailing, 24)
        .padding(.top, 16)
        .padding(.bottom, 17)
        .background(Color.white)
    }
}

private struct HistorySearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.subText)

            TextField("약속 이름이나 친구 이름을 검색하세요", text: $text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.text)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct HistoryCard: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // Wrapper 1
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.subText)
                            Text(item.dateText)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.subText)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.subText)
                            Text(item.timeText)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.subText)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .center, spacing: 10) {
                    StatusChip(status: item.status)

                    if item.status == .done {
                        Button(action: {}) {
                            Text("정산하기")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.22, green: 0.74, blue: 0.97),
                                                 Color(red: 0.01, green: 0.52, blue: 0.78)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(minWidth: 92, alignment: .center)
            }

            // Wrapper 2
            HStack {
                AvatarGroup(count: min(item.memberCount, 4), extra: item.extraCount)

                Text("\(item.memberCount)명 참여")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.subText)

                Spacer()

                HStack(spacing: 6) {
                    LocationPinIcon()
                        .frame(width: 14, height: 16)
                    Text(item.location)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.subText)
                }
            }
        }
        .padding(25)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.90, green: 0.91, blue: 0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

private struct AvatarGroup: View {
    let count: Int
    let extra: Int

    var body: some View {
        HStack(spacing: -8) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .fill(Color(red: 0.70, green: 0.72, blue: 0.76))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }

            if extra > 0 {
                Circle()
                    .fill(Color(red: 0.85, green: 0.87, blue: 0.90))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("+\(extra)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppColors.subText)
                    )
            }
        }
    }
}

private struct StatusChip: View {
    let status: HistoryStatus

    var body: some View {
        Text(status.title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(status.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.background)
            .clipShape(Capsule())
    }
}

private struct LocationPinIcon: View {
    var body: some View {
        LocationPinShape()
            .fill(AppColors.subText)
            .accessibilityHidden(true)
    }
}

private struct LocationPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 8.9568, y: 8.96583))
        path.addLine(to: CGPoint(x: 5.24813, y: 12.6758))
        path.addLine(to: CGPoint(x: 1.53945, y: 8.96583))
        path.addCurve(to: CGPoint(x: 0.174938, y: 6.58583),
                      control1: CGPoint(x: 0.863025, y: 8.29695),
                      control2: CGPoint(x: 0.408188, y: 7.50361))
        path.addCurve(to: CGPoint(x: 0.174938, y: 3.92583),
                      control1: CGPoint(x: -0.0583125, y: 5.69917),
                      control2: CGPoint(x: -0.0583125, y: 4.8125))
        path.addCurve(to: CGPoint(x: 1.53362, y: 1.54),
                      control1: CGPoint(x: 0.408188, y: 3.00806),
                      control2: CGPoint(x: 0.861081, y: 2.21278))
        path.addCurve(to: CGPoint(x: 3.9186, y: 0.169168),
                      control1: CGPoint(x: 2.20616, y: 0.867224),
                      control2: CGPoint(x: 3.00115, y: 0.410279))
        path.addCurve(to: CGPoint(x: 6.57765, y: 0.169168),
                      control1: CGPoint(x: 4.80495, y: -0.0563879),
                      control2: CGPoint(x: 5.6913, y: -0.0563879))
        path.addCurve(to: CGPoint(x: 8.96263, y: 1.54),
                      control1: CGPoint(x: 7.4951, y: 0.410279),
                      control2: CGPoint(x: 8.29009, y: 0.867224))
        path.addCurve(to: CGPoint(x: 10.3213, y: 3.92583),
                      control1: CGPoint(x: 9.63517, y: 2.21278),
                      control2: CGPoint(x: 10.0881, y: 3.00806))
        path.addCurve(to: CGPoint(x: 10.3213, y: 6.58583),
                      control1: CGPoint(x: 10.5546, y: 4.8125),
                      control2: CGPoint(x: 10.5546, y: 5.69917))
        path.addCurve(to: CGPoint(x: 8.9568, y: 8.96583),
                      control1: CGPoint(x: 10.0881, y: 7.50361),
                      control2: CGPoint(x: 9.63323, y: 8.29695))
        path.closeSubpath()

        path.move(to: CGPoint(x: 5.24813, y: 6.4225))
        path.addCurve(to: CGPoint(x: 5.83125, y: 6.265),
                      control1: CGPoint(x: 5.45805, y: 6.4225),
                      control2: CGPoint(x: 5.65242, y: 6.37))
        path.addCurve(to: CGPoint(x: 6.25693, y: 5.83917),
                      control1: CGPoint(x: 6.01008, y: 6.16),
                      control2: CGPoint(x: 6.15197, y: 6.01806))
        path.addCurve(to: CGPoint(x: 6.41437, y: 5.25583),
                      control1: CGPoint(x: 6.36189, y: 5.66028),
                      control2: CGPoint(x: 6.41437, y: 5.46583))
        path.addCurve(to: CGPoint(x: 6.25693, y: 4.6725),
                      control1: CGPoint(x: 6.41437, y: 5.04583),
                      control2: CGPoint(x: 6.36189, y: 4.85139))
        path.addCurve(to: CGPoint(x: 5.83125, y: 4.24667),
                      control1: CGPoint(x: 6.15197, y: 4.49361),
                      control2: CGPoint(x: 6.01008, y: 4.35167))
        path.addCurve(to: CGPoint(x: 5.24813, y: 4.08917),
                      control1: CGPoint(x: 5.65242, y: 4.14167),
                      control2: CGPoint(x: 5.45805, y: 4.08917))
        path.addCurve(to: CGPoint(x: 4.665, y: 4.24667),
                      control1: CGPoint(x: 5.0382, y: 4.08917),
                      control2: CGPoint(x: 4.84382, y: 4.14167))
        path.addCurve(to: CGPoint(x: 4.23932, y: 4.6725),
                      control1: CGPoint(x: 4.48618, y: 4.35167),
                      control2: CGPoint(x: 4.34428, y: 4.49361))
        path.addCurve(to: CGPoint(x: 4.08187, y: 5.25583),
                      control1: CGPoint(x: 4.13436, y: 4.85139),
                      control2: CGPoint(x: 4.08187, y: 5.04583))
        path.addCurve(to: CGPoint(x: 4.23932, y: 5.83917),
                      control1: CGPoint(x: 4.08187, y: 5.46583),
                      control2: CGPoint(x: 4.13436, y: 5.66028))
        path.addCurve(to: CGPoint(x: 4.665, y: 6.265),
                      control1: CGPoint(x: 4.34428, y: 6.01806),
                      control2: CGPoint(x: 4.48618, y: 6.16))
        path.addCurve(to: CGPoint(x: 5.24813, y: 6.4225),
                      control1: CGPoint(x: 4.84382, y: 6.37),
                      control2: CGPoint(x: 5.0382, y: 6.4225))
        path.closeSubpath()

        let scaleX = rect.width / 11.0
        let scaleY = rect.height / 13.0
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        return path.applying(transform)
    }
}

private struct SearchIcon: View {
    var body: some View {
        SearchIconShape()
            .fill(AppColors.subText)
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
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        return path.applying(transform)
    }
}

private enum HistoryStatus {
    case done
    case canceled

    var title: String {
        switch self {
        case .done: return "완료"
        case .canceled: return "취소됨"
        }
    }

    var background: Color {
        switch self {
        case .done: return Color(red: 0.88, green: 0.98, blue: 0.90)
        case .canceled: return Color(red: 0.98, green: 0.90, blue: 0.90)
        }
    }

    var textColor: Color {
        switch self {
        case .done: return Color(red: 0.18, green: 0.65, blue: 0.33)
        case .canceled: return Color(red: 0.83, green: 0.26, blue: 0.26)
        }
    }
}

private struct HistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let dateText: String
    let timeText: String
    let memberCount: Int
    let extraCount: Int
    let location: String
    let status: HistoryStatus
}

#Preview {
    HistoryView()
}
