//
//  AppointmentCard.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//

import SwiftUI

struct AppointmentCard: View {
    let title: String
    let members: String
    let dateText: String
    let badgeText: String? // "경로" 같은 작은 배지

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(title)
                    .font(AppFonts.body(16))
                    .foregroundStyle(AppColors.text)

                Spacer()

                if let badgeText {
                    Text(badgeText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            HStack {
                Text(members)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.subText)

                Spacer()

                Text(dateText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.subText)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
