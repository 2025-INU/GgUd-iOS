//
//  NotificationSettingsView.swift
//  GgUd
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // 상태값 (나중에 AppStorage / ViewModel로 바꾸면 됨)
    @State private var inviteNoti = false
    @State private var scheduleNoti = true
    @State private var friendRequestNoti = true
    @State private var pushNoti = true

    // MARK: - Layout Constants (Figma)
    private enum L {
        static let screenWidth: CGFloat = 375

        static let sectionWidth: CGFloat = 343
        static let sectionBottomPadding: CGFloat = 24

        static let appBarHeight: CGFloat = 69
        static let appBarPadTop: CGFloat = 16
        static let appBarPadH: CGFloat = 24
        static let appBarPadBottom: CGFloat = 17
        static let appBarBorder: CGFloat = 1

        static let cardRadius: CGFloat = 16
        static let cardShadowOpacity: CGFloat = 0.05  // #0000000D ≈ 5%
        static let cardShadowY: CGFloat = 1
        static let cardShadowBlur: CGFloat = 2

        static let appointmentCardHeight: CGFloat = 155
        static let singleCardHeight: CGFloat = 77

        static let rowHeight: CGFloat = 78
        static let rowPadTop: CGFloat = 16
        static let rowPadH: CGFloat = 24
        static let rowPadBottom: CGFloat = 17

        static let toggleW: CGFloat = 44
        static let toggleH: CGFloat = 24
    }

    var body: some View {
        VStack(spacing: 0) {
            // ✅ AppBar (Figma)
            AppBar(
                title: "알림 설정",
                onBack: { dismiss() }
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ===== 약속 알림 (wrapping: width 343, bottom padding 24)
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "약속 알림")

                        AppointmentAlarmCard(inviteNoti: $inviteNoti, scheduleNoti: $scheduleNoti)

                    }
                    .frame(width: L.sectionWidth, alignment: .leading)
                    .padding(.bottom, L.sectionBottomPadding)
                    .padding(.top, 18) // 섹션 시작 여백(원하면 피그마 수치 주면 맞춤)

                    // ===== 친구 알림 (wrapping: width 343, bottom padding 24)
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "친구 알림")

                        Card(height: L.singleCardHeight) {
                            SingleRow(
                                title: "친구 요청",
                                subtitle: "새로운 친구 요청을 받을 때 알림",
                                isOn: $friendRequestNoti
                            )
                        }
                    }
                    .frame(width: L.sectionWidth, alignment: .leading)
                    .padding(.bottom, L.sectionBottomPadding)

                    // ===== 알림 방식 (wrapping: width 343)
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "알림 방식")

                        Card(height: L.singleCardHeight) {
                            SingleRow(
                                title: "푸시 알림",
                                subtitle: "앱 푸시 알림 받기",
                                isOn: $pushNoti
                            )
                        }
                    }
                    .frame(width: L.sectionWidth, alignment: .leading)

                    // ===== 설정 저장 버튼 (수치 아직 미정이라 “스샷 느낌”으로만)
                    Button {
                        // TODO: 저장 로직 연결 (AppStorage면 사실상 자동 저장이라 토스트만 띄워도 됨)
                    } label: {
                        Text("설정 저장")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: L.sectionWidth, height: 56)
                            .background(Color(hex: "#3B82F6"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, (L.screenWidth - L.sectionWidth) / 2) // 375 기준 가운데 정렬
            }
            .background(Color("Background"))
        }
        .navigationBarHidden(true)
    }
}

// MARK: - AppBar (Figma: 375x69, padding 16/24/17/24, bottom border 1)

private struct AppBar: View {
    let title: String
    let onBack: () -> Void

    private enum A {
        static let height: CGFloat = 69
        static let padTop: CGFloat = 16
        static let padH: CGFloat = 24
        static let padBottom: CGFloat = 17
        static let border: CGFloat = 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.primary)
                }

                Text(title)
                    .font(.system(size: 20, weight: .bold))

                Spacer()
            }
            .padding(.top, A.padTop)
            .padding(.horizontal, A.padH)
            .padding(.bottom, A.padBottom)
            .frame(height: A.height)

            Rectangle()
                .fill(Color(hex: "#E5E7EB"))
                .frame(height: 1)
        }
        .background(Color("#FFFFFF"))
    }
}

// MARK: - Section Title

private struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 8) // 너가 예전에 준 타이틀 래핑 padding L/R 8
            .frame(height: 20, alignment: .center)
    }
}

// MARK: - Card (Figma: width 343, radius 16, shadow 0 1 2 #0000000D)

private struct Card<Content: View>: View {
    let height: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .frame(width: 343, height: height)
            .background(Color(hex: "#ffffff"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: Color.black.opacity(0.05), // #0000000D
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

private struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "#E5E7EB"))
            .frame(height: 1)
            .padding(.horizontal, 24)
    }
}

// MARK: - Rows

private struct NotiRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "#6B7280"))
            }

            Spacer()

            CustomSwitch(isOn: $isOn)
        }
        .frame(height: 78)
        .padding(.top, 16)
        .padding(.horizontal, 24)
        .padding(.bottom, 17)
    }
}

// 단일 카드(높이 77) 안에서 row가 가운데로 자연스럽게 보이게 살짝 컴팩트한 버전
private struct SingleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "#6B7280"))
            }

            Spacer()

            CustomSwitch(isOn: $isOn)
        }
        .frame(height: 77)
        .padding(.horizontal, 24)
    }
}

// MARK: - Custom Switch (Figma: 44x24)

private struct CustomSwitch: View {
    @Binding var isOn: Bool

    private let trackSize = CGSize(width: 44, height: 24)
    private let thumb: CGFloat = 16
    private let inset: CGFloat = 4

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isOn.toggle()
            }
        } label: {
            RoundedRectangle(cornerRadius: 9999, style: .continuous)
                .fill(isOn ? Color(hex: "#3B82F6") : Color(hex: "#D1D5DB"))
                .frame(width: trackSize.width, height: trackSize.height)
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumb, height: thumb)
                        .offset(x: isOn ? (trackSize.width - thumb - inset) : inset)
                        .shadow(color: Color.black.opacity(0.10), radius: 1, x: 0, y: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Appointment Alarm Card (Figma: 343x155)

private struct AppointmentAlarmCard: View {
    @Binding var inviteNoti: Bool
    @Binding var scheduleNoti: Bool

    private enum F {
        static let width: CGFloat = 343
        static let height: CGFloat = 155
        static let radius: CGFloat = 16

        static let rowHeight: CGFloat = 77
        static let padV: CGFloat = 16
        static let padH: CGFloat = 24

        // shadow: 0px 1px 2px #0000000D
        static let shadowOpacity: Double = 0.05
        static let shadowRadius: CGFloat = 2
        static let shadowY: CGFloat = 1
    }

    var body: some View {
        VStack(spacing: 0) {
            AppointmentRow(
                title: "약속 초대",
                subtitle: "새로운 약속 초대를 받을 때 알림",
                isOn: $inviteNoti
            )
            .frame(height: F.rowHeight)

            Rectangle()
                .fill(Color("Border").opacity(1))
                .frame(height: 1)

            AppointmentRow(
                title: "약속 알림",
                subtitle: "예정된 약속 전 미리 알림",
                isOn: $scheduleNoti
            )
            .frame(height: F.rowHeight)
        }
        .frame(width: F.width, height: F.height)
        .background(Color(hex: "#ffffff"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(
                        color: Color.black.opacity(0.05), // #0000000D
                        radius: 2,
                        x: 0,
                        y: 1
                    )
    }
}

private struct AppointmentRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color("SubText")) // #6B7280
            }

            Spacer(minLength: 12)

            CustomSwitch(isOn: $isOn)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
    }
}
