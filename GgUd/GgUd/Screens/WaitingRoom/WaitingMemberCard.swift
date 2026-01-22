//
//  WaitingMemberCard.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct WaitingMemberCard: View {
    let name: String
    let location: String
    let transport: TransportType

    var body: some View {
        HStack(spacing: 14) {

            // 왼쪽 아이콘(프로필)
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.black.opacity(0.9))

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)

                Text(location)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.black.opacity(0.85))
            }

            Spacer()

            Text(transport.displayText)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.black.opacity(0.85))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.black, lineWidth: 1)
        )
        .cornerRadius(6)
    }
}
