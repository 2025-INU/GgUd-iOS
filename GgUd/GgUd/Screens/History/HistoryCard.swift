import SwiftUI

enum HistoryStatus: Equatable {
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

struct HistoryItem: Identifiable {
    let id = UUID()
    let title: String
    let dateText: String
    let timeText: String
    let memberCount: Int
    let location: String
    let status: HistoryStatus
}

struct HistoryCard: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                HistoryCardContent(
                    title: item.title,
                    date: item.dateText,
                    time: item.timeText
                )

                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    StatusChip(status: item.status)

                    if item.status == .done {
                        NavigationLink {
                            SettlementView(appointmentTitle: item.title)
                        } label: {
                            Text("정산하기")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 75.5, height: 28)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#38BDF8"), Color(hex: "#0284C7")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 92)
            }
            .frame(height: 80)

            Spacer().frame(height: 14)

            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    PeopleGroupIcon(totalCount: item.memberCount)
                    Text("\(item.memberCount)명 참여")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#4B5563"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    HomeLocationPinIcon()
                        .frame(width: 11, height: 13)
                    Text(item.location)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#4B5563"))
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 176)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HistoryCardContent: View {
    let title: String
    let date: String
    let time: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "#111827"))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    HomeDateIcon()
                        .frame(width: 12, height: 12)
                    Text(date)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#4B5563"))
                }

                HStack(spacing: 8) {
                    HomeTimeIcon()
                        .frame(width: 12, height: 12)
                    Text(time)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#4B5563"))
                }
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
            .frame(minWidth: 50, minHeight: 28)
            .background(status.background)
            .clipShape(Capsule())
    }
}

private struct PeopleGroupIcon: View {
    let totalCount: Int

    private let visibleLimit = 4
    private var visibleCount: Int { min(totalCount, visibleLimit) }
    private var extraCount: Int { max(0, totalCount - visibleLimit) }
    private var circleCount: Int { visibleCount + (extraCount > 0 ? 1 : 0) }
    private var iconWidth: CGFloat {
        guard circleCount > 0 else { return 0 }
        return 28 + CGFloat(circleCount - 1) * 20
    }

    var body: some View {
        HStack(spacing: -8) {
            ForEach(0..<visibleCount, id: \.self) { _ in
                Circle()
                    .fill(Color(hex: "#9CA3AF"))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }

            if extraCount > 0 {
                Circle()
                    .fill(Color(hex: "#D1D5DB"))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("+\(extraCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "#4B5563"))
                    )
            }
        }
        .frame(width: iconWidth, height: 28, alignment: .leading)
    }
}
