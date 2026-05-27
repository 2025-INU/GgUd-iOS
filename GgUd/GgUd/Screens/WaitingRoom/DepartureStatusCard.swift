//
//  DepartureStatusCard.swift
//  GgUd
//
//

import SwiftUI



struct WaitingMember: Identifiable {
    let userId: Int64?
    let name: String
    let statusText: String
    let isDone: Bool
    let isHost: Bool
    let profileImageURL: String?
    let profileImageData: Data?

    var id: String {
        if let userId {
            return "user-\(userId)"
        }
        return "name-\(name)"
    }
}

struct WaitingMemberRowCard: View {
    let member: WaitingMember

    var body: some View {
        HStack(spacing: 14) {
            WaitingMemberAvatarView(
                profileImageURL: member.profileImageURL,
                profileImageData: member.profileImageData
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
            if member.isDone {
                Circle()
                    .fill(Color(hex: "#DCFCE7"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "#16A34A"))
                    )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color(hex: "#F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: CardStyle.shadowColor,
            radius: CardStyle.shadowRadius,
            x: CardStyle.shadowX,
            y: CardStyle.shadowY
        )
    }
}

private struct WaitingMemberAvatarView: View {
    let profileImageURL: String?
    let profileImageData: Data?

    var body: some View {
        Group {
            if let profileImageData, let image = UIImage(data: profileImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let profileImageURL, let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }

    private var placeholder: some View {
        Circle()
            .fill(AppColors.primary)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}

#Preview {
    VStack(spacing: 12) {
        WaitingMemberRowCard(member: .init(userId: 1, name: "(호스트) 김민수 (나)", statusText: "위치 입력 완료", isDone: true, isHost: true, profileImageURL: nil, profileImageData: nil))
        WaitingMemberRowCard(member: .init(userId: 2, name: "박지훈", statusText: "위치 입력 대기중", isDone: false, isHost: false, profileImageURL: nil, profileImageData: nil))
    }
    .padding()
    .background(AppColors.background)
}
