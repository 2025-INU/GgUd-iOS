//
//  KakaoShareButton.swift
//  GgUd
//


import SwiftUI

struct KakaoShareButton: View {
    let title: String
    let onTap: () -> Void

    init(title: String = "카카오톡으로 링크 공유", onTap: @escaping () -> Void) {
        self.title = title
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // 아이콘 (이미지 없으면 SF Symbol로 대체)
                KakaoIcon()
                    .frame(width: 26, height: 26)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(red: 1.0, green: 0.84, blue: 0.0)) // 카카오 노랑 느낌
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .shadow(
            color: CardStyle.shadowColor,
            radius: CardStyle.shadowRadius,
            x: CardStyle.shadowX,
            y: CardStyle.shadowY
        )
    }
}

private struct KakaoIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.85))

            Image(systemName: "message.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack {
        KakaoShareButton {
            print("kakao share")
        }
        .padding()
    }
    .background(AppColors.background)
}
