//
//  LoginView.swift
//  GgUd
//
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 18) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.23, green: 0.55, blue: 0.98),
                                         Color(red: 0.12, green: 0.44, blue: 0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 96, height: 96)
                            .overlay(
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.white)
                            )

                        Text("GgUd")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        Text("친구들과의 완벽한 만남을 위한\n중간지점 찾기 서비스")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(AppColors.subText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 16) {
                        FeatureCard(
                            icon: "person.2.fill",
                            tint: Color(red: 0.22, green: 0.46, blue: 0.98),
                            title: "친구들과 약속 생성",
                            subtitle: "간편하게 약속을 만들고 친구들을 초대"
                        )

                        FeatureCard(
                            icon: "location.fill",
                            tint: Color(red: 0.02, green: 0.52, blue: 0.82),
                            title: "위치 기반 중간지점",
                            subtitle: "모든 참여자를 고려한 최적의 만남 장소"
                        )

                        FeatureCard(
                            icon: "fork.knife",
                            tint: Color(red: 0.00, green: 0.60, blue: 0.36),
                            title: "맞춤 장소 추천",
                            subtitle: "카페, 식당 등 목적에 맞는 장소 추천"
                        )
                    }

                    VStack(spacing: 12) {
                        Button(action: {}) {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)

                                Text("카카오톡으로 시작하기")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.15, green: 0.46, blue: 0.98),
                                             Color(red: 0.06, green: 0.55, blue: 0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
                        }
                        .buttonStyle(.plain)

                        Text("카카오톡 계정으로 간편하게 시작하세요")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppColors.subText)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.visible, for: .tabBar)
    }
}

private struct FeatureCard: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(tint)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.subText)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    LoginView()
}
