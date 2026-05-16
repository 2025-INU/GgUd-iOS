//
//  MyPageView.swift
//  GgUd
//

import SwiftUI
import KakaoSDKUser

struct MyPageView: View {
    @EnvironmentObject private var userSession: UserSessionStore

    var body: some View {
        ZStack {
            Color(hex: "#F9FAFB").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                profileRow

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("계정")
                        accountCard
                            .padding(.bottom, 24)

                        sectionTitle("이용 안내")
                        guideCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("마이페이지")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "#111827"))
                Spacer()
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(Color.white)

            Rectangle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(height: 1)
        }
    }

    private var profileRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ProfileAvatarView(
                    profileImageURL: userSession.profileImageURL,
                    profileImageData: userSession.profileImageData,
                    size: 64,
                    placeholderSystemImage: "person.crop.circle.fill"
                )

                Text(displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "#111827"))

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .background(Color.white)

            Rectangle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(height: 1)
        }
    }

    private var accountCard: some View {
        VStack(spacing: 0) {
            menuRow(systemImage: "person.fill", title: "프로필 수정") {
                ProfileEditView()
            }
            divider
            buttonRow(systemImage: "rectangle.portrait.and.arrow.right", title: "로그아웃") {
                performLogout()
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var guideCard: some View {
        VStack(spacing: 0) {
            buttonRow(systemImage: "questionmark.circle", title: "문의하기") {
                // TODO
            }
            divider
            buttonRow(systemImage: "doc.text", title: "이용약관") {
                // TODO
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(hex: "#6B7280"))
            .padding(.leading, 4)
            .padding(.bottom, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: "#F9FAFB"))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    private func menuRow<Destination: View>(systemImage: String, title: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            rowContent(systemImage: systemImage, title: title)
        }
        .buttonStyle(.plain)
    }

    private func buttonRow(systemImage: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowContent(systemImage: systemImage, title: title)
        }
        .buttonStyle(.plain)
    }

    private func rowContent(systemImage: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 19)
                .foregroundStyle(Color(hex: "#111827"))

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#111827"))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#9CA3AF"))
        }
        .padding(16)
        .frame(height: 60)
        .contentShape(Rectangle())
    }

    private var displayName: String {
        guard userSession.isLoggedIn else { return "로그인을 해주세요" }
        let trimmed = userSession.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "사용자" : trimmed
    }

    private func performLogout() {
        let finishLogout = {
            UserApi.shared.logout { error in
                if let error {
                    print("[KakaoLogin] logout error:", error.localizedDescription)
                    print("[KakaoLogin] logout full error:", error)
                } else {
                    print("[KakaoLogin] logout success")
                }

                DispatchQueue.main.async {
                    userSession.logout()
                }
            }
        }

        if let accessToken = userSession.backendAccessToken, !accessToken.isEmpty {
            AuthAPIClient.shared.logout(
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer"
            ) { result in
                switch result {
                case .success:
                    print("[KakaoLogin] backend logout success")
                case let .failure(error):
                    print("[KakaoLogin] backend logout error:", error.localizedDescription)
                }

                finishLogout()
            }
        } else {
            finishLogout()
        }
    }
}

private struct ProfileAvatarView: View {
    let profileImageURL: String?
    let profileImageData: Data?
    let size: CGFloat
    let placeholderSystemImage: String

    var body: some View {
        if let profileImageData,
           let image = UIImage(data: profileImageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if let profileImageURL,
                  let rawURL = URL(string: profileImageURL) {
            let bustedURL = cacheBustedURL(from: rawURL)
            AsyncImage(url: bustedURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case let .failure(error):
                    let _ = print("[ProfileAvatar] image load failed:", error.localizedDescription)
                    placeholder
                case .empty:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .id(profileImageURL)
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: placeholderSystemImage)
            .font(.system(size: size))
            .foregroundStyle(Color(hex: "#D1D5DB"))
    }

    private func cacheBustedURL(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970))))
        components.queryItems = queryItems
        return components.url ?? url
    }
}


#Preview {
    NavigationStack {
        MyPageView()
    }
    .environmentObject(UserSessionStore())
}
