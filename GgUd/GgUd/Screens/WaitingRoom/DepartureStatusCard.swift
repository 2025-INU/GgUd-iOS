//
//  DepartureStatusCard.swift
//  GgUd
//
//

import SwiftUI



struct WaitingMember: Identifiable {
    let id = UUID()
    let name: String
    let statusText: String
    let isDone: Bool
}

struct WaitingMemberRowCard: View {
    let member: WaitingMember

    var body: some View {
        HStack(spacing: 14) {
            // 왼쪽 프로필 원
            Circle()
                .fill(AppColors.primary)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.text)

                Text(member.statusText)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.subText)
            }

            Spacer()

            // 오른쪽 상태(완료 체크)
            Circle()
                .fill(member.isDone ? Color.green.opacity(0.15) : Color.gray.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: member.isDone ? "checkmark" : "clock")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(member.isDone ? Color.green : Color.gray)
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
    VStack(spacing: 12) {
        WaitingMemberRowCard(member: .init(name: "김민수 (나)", statusText: "위치 입력 완료", isDone: true))
        WaitingMemberRowCard(member: .init(name: "박지훈", statusText: "위치 입력 대기중", isDone: false))
    }
    .padding()
    .background(AppColors.background)
}
