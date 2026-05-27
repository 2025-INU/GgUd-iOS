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
                KakaoIcon()
                    .frame(width: 18, height: 17)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "#111827"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#FACC15"), Color(hex: "#EAB308")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.10), radius: 15, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
    }
}

private struct KakaoIcon: View {
    var body: some View {
        Image("KakaoShareIcon")
            .resizable()
            .renderingMode(.original)
            .aspectRatio(contentMode: .fit)
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
