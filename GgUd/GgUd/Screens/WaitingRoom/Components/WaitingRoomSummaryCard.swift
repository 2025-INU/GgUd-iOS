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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.30, green: 0.70, blue: 1.0),
                                 Color(red: 0.22, green: 0.56, blue: 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    Text("\(dateText) · \(timeText)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.subText)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.13, green: 0.64, blue: 0.25))

                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.13, green: 0.64, blue: 0.25))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.92, green: 0.97, blue: 1.0))
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
