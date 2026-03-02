import SwiftUI

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            NotificationTopBar(
                title: "알림",
                trailingText: "모두 읽음",
                onBack: { dismiss() }
            )

            Spacer().frame(height: 11)

            VStack(spacing: 8) {
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
                    showActionButtons: true,
                    onReject: {},
                    onAccept: {}
                )

                NotificationCard(
                    title: "회사 동료 점심 모임이 1일 남았어요",
                    descript: "내일 12:30에 강남역에서 만나요",
                    time: "1시간 전",
                    isUnread: false,
                    iconStyle: .reminder
                )

                NotificationCard(
                    title: "대학 동기 모임이 3일 남았어요",
                    descript: "12월 20일 18:00에 역삼역에서 만나요",
                    time: "어제",
                    isUnread: false,
                    iconStyle: .reminder
                )
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#F9FAFB"))
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Top Bar

private struct NotificationTopBar: View {
    let title: String
    let trailingText: String
    let onBack: () -> Void

    private enum S {
        static let topBarHeight: CGFloat = 69
        static let topBarPaddingTop: CGFloat = 16
        static let topBarPaddingBottom: CGFloat = 17
        static let topBarBorderHeight: CGFloat = 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Spacer()

                Text(trailingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#2563EB"))
            }
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .padding(.leading, 24)
            .padding(.trailing, 24)
            .padding(.top, S.topBarPaddingTop)
            .padding(.bottom, S.topBarPaddingBottom)
            .frame(height: S.topBarHeight, alignment: .center)

            Rectangle()
                .fill(AppColors.border)
                .frame(height: S.topBarBorderHeight)
        }
        .background(Color.white)
    }
}

#Preview {
    NavigationStack {
        NotificationView()
    }
}
