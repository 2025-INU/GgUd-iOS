//
//  LoginView.swift
//  GgUd
//
//
// iOS SDK
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser


import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isLoggingIn = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 18) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#3B82F6"),
                                         Color(hex: "#0284C7")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 96, height: 96)
                            .overlay(
                                LoginMapPinIcon()
                                    .frame(width: 30, height: 36)
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
                        Button(action: loginWithKakao) {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)

                                Text(isLoggingIn ? "로그인 중..." : "카카오톡으로 시작하기")
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
                        .disabled(isLoggingIn)

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
        .toolbar(.hidden, for: .tabBar)
        .alert("카카오 로그인", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func loginWithKakao() {
        isLoggingIn = true
        print("[KakaoLogin] start")
        print("[KakaoLogin] isKakaoTalkLoginAvailable:", UserApi.isKakaoTalkLoginAvailable())

        if UserApi.isKakaoTalkLoginAvailable() {
            print("[KakaoLogin] trying loginWithKakaoTalk")
            UserApi.shared.loginWithKakaoTalk { token, error in
                handleLoginResult(token: token, error: error, fallbackToAccount: true)
            }
        } else {
            print("[KakaoLogin] fallback to loginWithKakaoAccount")
            loginWithKakaoAccount()
        }
    }

    private func loginWithKakaoAccount() {
        print("[KakaoLogin] trying loginWithKakaoAccount")
        UserApi.shared.loginWithKakaoAccount { token, error in
            handleLoginResult(token: token, error: error, fallbackToAccount: false)
        }
    }

    private func handleLoginResult(token: OAuthToken?, error: Error?, fallbackToAccount: Bool) {
        if let error {
            print("[KakaoLogin] login error:", error.localizedDescription)
            print("[KakaoLogin] full error:", error)

            if fallbackToAccount {
                print("[KakaoLogin] loginWithKakaoTalk failed, retrying with KakaoAccount")
                loginWithKakaoAccount()
                return
            }

            isLoggingIn = false
            alertMessage = "로그인에 실패했습니다.\n\(error.localizedDescription)"
            showAlert = true
            return
        }

        guard token != nil else {
            print("[KakaoLogin] token is nil")
            isLoggingIn = false
            alertMessage = "토큰을 받지 못했습니다."
            showAlert = true
            return
        }

        print("[KakaoLogin] token received")

        UserApi.shared.me { user, error in
            isLoggingIn = false

            if let error {
                print("[KakaoLogin] me() error:", error.localizedDescription)
                print("[KakaoLogin] me() full error:", error)
                alertMessage = "사용자 정보를 가져오지 못했습니다.\n\(error.localizedDescription)"
                showAlert = true
                return
            }

            let nickname = user?.kakaoAccount?.profile?.nickname ?? "사용자"
            print("[KakaoLogin] me() success")
            print("[KakaoLogin] user id:", user?.id ?? 0)
            print("[KakaoLogin] nickname:", nickname)
            alertMessage = "\(nickname) 로그인 성공"
            showAlert = true
            dismiss()
        }
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
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.8))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "#F3F4F6"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    LoginView()
}

private struct LoginMapPinIcon: View {
    var body: some View {
        ZStack {
            LoginMapPinShape()
                .fill(Color.white)
            Circle()
                .fill(Color(red: 0.14, green: 0.49, blue: 0.95))
                .frame(width: 8, height: 8)
                .offset(y: -6)
        }
        .accessibilityHidden(true)
    }
}

private struct LoginMapPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 8.9568, y: 8.96583))
        path.addLine(to: CGPoint(x: 5.24813, y: 12.6758))
        path.addLine(to: CGPoint(x: 1.53945, y: 8.96583))
        path.addCurve(to: CGPoint(x: 0.174938, y: 6.58583),
                      control1: CGPoint(x: 0.863025, y: 8.29695),
                      control2: CGPoint(x: 0.408188, y: 7.50361))
        path.addCurve(to: CGPoint(x: 0.174938, y: 3.92583),
                      control1: CGPoint(x: -0.0583125, y: 5.69917),
                      control2: CGPoint(x: -0.0583125, y: 4.8125))
        path.addCurve(to: CGPoint(x: 1.53362, y: 1.54),
                      control1: CGPoint(x: 0.408188, y: 3.00806),
                      control2: CGPoint(x: 0.861081, y: 2.21278))
        path.addCurve(to: CGPoint(x: 3.9186, y: 0.169168),
                      control1: CGPoint(x: 2.20616, y: 0.867224),
                      control2: CGPoint(x: 3.00115, y: 0.410279))
        path.addCurve(to: CGPoint(x: 6.57765, y: 0.169168),
                      control1: CGPoint(x: 4.80495, y: -0.0563879),
                      control2: CGPoint(x: 5.6913, y: -0.0563879))
        path.addCurve(to: CGPoint(x: 8.96263, y: 1.54),
                      control1: CGPoint(x: 7.4951, y: 0.410279),
                      control2: CGPoint(x: 8.29009, y: 0.867224))
        path.addCurve(to: CGPoint(x: 10.3213, y: 3.92583),
                      control1: CGPoint(x: 9.63517, y: 2.21278),
                      control2: CGPoint(x: 10.0881, y: 3.00806))
        path.addCurve(to: CGPoint(x: 10.3213, y: 6.58583),
                      control1: CGPoint(x: 10.5546, y: 4.8125),
                      control2: CGPoint(x: 10.5546, y: 5.69917))
        path.addCurve(to: CGPoint(x: 8.9568, y: 8.96583),
                      control1: CGPoint(x: 10.0881, y: 7.50361),
                      control2: CGPoint(x: 9.63323, y: 8.29695))
        path.closeSubpath()

        let scaleX = rect.width / 11.0
        let scaleY = rect.height / 13.0
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        return path.applying(transform)
    }
}
