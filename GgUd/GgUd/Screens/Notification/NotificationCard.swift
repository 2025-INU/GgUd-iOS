import SwiftUI

struct NotificationCard: View {
    let title: String
    let descript: String
    let time: String
    let isUnread: Bool
    let iconStyle: NotificationIconStyle
    var showActionButtons: Bool = false
    var onReject: () -> Void = {}
    var onAccept: () -> Void = {}

    var body: some View {
        Group {
            if isUnread {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)

                    NotificationCardContent(
                        title: title,
                        descript: descript,
                        time: time,
                        isUnread: isUnread,
                        iconStyle: iconStyle,
                        showActionButtons: showActionButtons,
                        onReject: onReject,
                        onAccept: onAccept
                    )
                    .padding(17)
                    .frame(width: 336, alignment: .leading)
                    .frame(minHeight: showActionButtons ? 118 : 102)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .frame(width: 343, alignment: .leading)
                .background(Color(hex: "#3B82F6"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                NotificationCardContent(
                    title: title,
                    descript: descript,
                    time: time,
                    isUnread: isUnread,
                    iconStyle: iconStyle,
                    showActionButtons: showActionButtons,
                    onReject: onReject,
                    onAccept: onAccept
                )
                .padding(17)
                .frame(width: 343, alignment: .leading)
                .frame(minHeight: showActionButtons ? 118 : 102)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private struct NotificationCardContent: View {
    let title: String
    let descript: String
    let time: String
    let isUnread: Bool
    let iconStyle: NotificationIconStyle
    let showActionButtons: Bool
    let onReject: () -> Void
    let onAccept: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            icon
                .frame(width: 48, height: 48)

            Spacer().frame(width: 12)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "#111827"))
                    .lineLimit(1)

                Spacer().frame(height: 4)

                Text(descript)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "#4B5563"))
                    .lineLimit(1)

                Spacer().frame(height: 8)

                HStack(spacing: 10) {
                    Text(time)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: "#6B7280"))

                    if showActionButtons {
                        Spacer()

                        Button("거절", action: onReject)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "#4B5563"))
                            .frame(width: 46, height: 24)
                            .background(Color(hex: "#E5E7EB"))
                            .clipShape(Capsule())
                            .buttonStyle(.plain)

                        Button("수락", action: onAccept)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 24)
                            .background(Color(hex: "#3B82F6"))
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                    }
                }
            }

            if isUnread {
                Spacer(minLength: 0)

                Circle()
                    .fill(Color(hex: "#3B82F6"))
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        Circle()
            .fill(iconStyle.gradient)
            .overlay {
                Image(systemName: iconStyle.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

enum NotificationIconStyle {
    case friendAdded
    case invite
    case reminder

    var symbol: String {
        switch self {
        case .friendAdded: return "person.badge.plus.fill"
        case .invite: return "calendar"
        case .reminder: return "clock.fill"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .friendAdded:
            return LinearGradient(
                colors: [Color(hex: "#3B82F6"), Color(hex: "#2563EB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .invite:
            return LinearGradient(
                colors: [Color(hex: "#A855F7"), Color(hex: "#9333EA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .reminder:
            return LinearGradient(
                colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        NotificationCard(
            title: "김민수와 친구가 되었어요",
            descript: "이제 김민수와 약속을 잡을 수 있어요!",
            time: "방금 전",
            isUnread: true,
            iconStyle: .friendAdded
        )
        NotificationCard(
            title: "이지은이 약속에 초대했어요",
            descript: "'대학 동기 모임'에 참여해보세요",
            time: "10분 전",
            isUnread: true,
            iconStyle: .invite,
            showActionButtons: true
        )
    }
    .padding()
    .background(Color(hex: "#F9FAFB"))
}
