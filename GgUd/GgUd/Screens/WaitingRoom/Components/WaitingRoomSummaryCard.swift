//
//  WaitingRoomSummaryCard.swift
//  GgUd
//

import SwiftUI

struct WaitingRoomSummaryCard: View {
    let title: String
    let dateText: String
    let timeText: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 아이콘
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                HStack(spacing: 10) {
                    Label(dateText, systemImage: "calendar")
                        .labelStyle(.titleAndIcon)
                    Label(timeText, systemImage: "clock")
                        .labelStyle(.titleAndIcon)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.subText)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.subText)
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.92, green: 0.97, blue: 1.0)) // 연한 하늘색
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CardStyle.borderColor, lineWidth: CardStyle.borderWidth)
        )
        .shadow(
            color: CardStyle.shadowColor,
            radius: CardStyle.shadowRadius,
            x: CardStyle.shadowX,
            y: CardStyle.shadowY
        )
    }
}

#Preview {
    WaitingRoomSummaryCard(
        title: "은석 생일",
        dateText: "2026-02-01",
        timeText: "19:00",
        subtitle: "약속이 생성되었습니다! 친구들을 초대해보세요."
    )
    .padding()
    .background(AppColors.background)
}
