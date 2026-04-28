//
//  AppRootView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//

import SwiftUI

struct AppRootView: View {
    fileprivate enum Tab {
        case home
        case history
        case mypage
    }

    @State private var selected: Tab = .home
    @State private var homePath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var mypagePath = NavigationPath()
    @EnvironmentObject private var userSession: UserSessionStore
    @State private var didSyncMyInfo = false

    var body: some View {
        ZStack {
            Group {
                switch selected {
                case .home:
                    NavigationStack(path: $homePath) {
                        HomeView()
                    }
                case .history:
                    NavigationStack(path: $historyPath) {
                        HistoryView()
                    }
                case .mypage:
                    NavigationStack(path: $mypagePath) {
                        MyPageView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            if userSession.isLoggedIn {
                CustomTabBar(selected: $selected) { tab in
                    switch tab {
                    case .home:
                        homePath = NavigationPath()
                    case .history:
                        historyPath = NavigationPath()
                    case .mypage:
                        mypagePath = NavigationPath()
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(
            isPresented: Binding(
                get: { !userSession.isLoggedIn },
                set: { _ in }
            )
        ) {
            NavigationStack {
                LoginView()
            }
        }
        .task(id: userSession.backendAccessToken) {
            guard userSession.isLoggedIn,
                  !didSyncMyInfo
            else { return }

            didSyncMyInfo = true
            syncMyInfoOnLaunch()
        }
        .onChange(of: userSession.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                didSyncMyInfo = false
            }
        }
    }

    private func syncMyInfoOnLaunch() {
        if let accessToken = userSession.backendAccessToken, !accessToken.isEmpty {
            fetchMyInfo(accessToken: accessToken, tokenType: userSession.backendTokenType ?? "Bearer")
            return
        }

        refreshBackendAccessTokenIfNeeded { success in
            if !success {
                DispatchQueue.main.async {
                    didSyncMyInfo = false
                }
            }
        }
    }

    private func fetchMyInfo(accessToken: String, tokenType: String) {
        AuthAPIClient.shared.getMyInfo(
            accessToken: accessToken,
            tokenType: tokenType
        ) { result in
            switch result {
            case let .success(myInfo):
                print("[KakaoLogin] app launch getMyInfo success")
                DispatchQueue.main.async {
                    userSession.updateProfile(
                        userId: myInfo.id,
                        nickname: myInfo.nickname,
                        profileImageURL: myInfo.profileImageUrl
                    )
                }
            case let .failure(error):
                print("[KakaoLogin] app launch getMyInfo error:", error.localizedDescription)
                guard case let AuthAPIError.server(statusCode, _) = error, statusCode == 401 else {
                    DispatchQueue.main.async {
                        didSyncMyInfo = false
                    }
                    return
                }

                print("[KakaoLogin] access token expired, trying refresh")
                refreshBackendAccessTokenIfNeeded()
            }
        }
    }

    private func refreshBackendAccessTokenIfNeeded(completion: ((Bool) -> Void)? = nil) {
        guard let refreshToken = userSession.backendRefreshToken, !refreshToken.isEmpty else {
            print("[KakaoLogin] no refresh token available")
            DispatchQueue.main.async {
                completion?(false)
            }
            return
        }

        AuthAPIClient.shared.refreshToken(refreshToken: refreshToken) { result in
            switch result {
            case let .success(response):
                guard let accessToken = response.accessToken, !accessToken.isEmpty else {
                    print("[KakaoLogin] refresh succeeded but access token was empty")
                    DispatchQueue.main.async {
                        didSyncMyInfo = false
                        completion?(false)
                    }
                    return
                }

                print("[KakaoLogin] refresh success")
                DispatchQueue.main.async {
                    userSession.updateBackendTokens(
                        accessToken: accessToken,
                        tokenType: response.tokenType ?? userSession.backendTokenType ?? "Bearer",
                        expiresIn: response.expiresIn
                    )
                    fetchMyInfo(
                        accessToken: accessToken,
                        tokenType: response.tokenType ?? userSession.backendTokenType ?? "Bearer"
                    )
                    completion?(true)
                }
            case let .failure(error):
                print("[KakaoLogin] refresh error:", error.localizedDescription)
                DispatchQueue.main.async {
                    didSyncMyInfo = false
                    userSession.logout()
                    completion?(false)
                }
            }
        }
    }
}

private struct CustomTabBar: View {
    @Binding var selected: AppRootView.Tab
    let onSelect: (AppRootView.Tab) -> Void

    private let accent = Color(red: 0.0, green: 0.58, blue: 0.87)
    private let selectedBackground = Color(red: 0.93, green: 0.97, blue: 1.0)
    private let unselected = Color(red: 0.35, green: 0.38, blue: 0.42)

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabButton(tab: .home, title: "홈", systemImage: "house")
                tabButton(tab: .history, title: "히스토리", systemImage: "clock.arrow.circlepath")
                tabButton(tab: .mypage, title: "마이페이지", systemImage: "person")
            }
            .padding(.top, 1)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74, alignment: .top)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.86, green: 0.88, blue: 0.90))
                .frame(height: 1)
        }
        .background(Color.white)
    }

    private func tabButton(tab: AppRootView.Tab, title: String, systemImage: String) -> some View {
        let isSelected = selected == tab

        return Button {
            selected = tab
            onSelect(tab)
        } label: {
            ZStack(alignment: .top) {
                if isSelected {
                    Rectangle()
                        .fill(accent)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                VStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .regular))
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.top, 9)
                .padding(.bottom, 9)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .foregroundStyle(isSelected ? accent : unselected)
            .background(isSelected ? selectedBackground : Color.white)
        }
        .buttonStyle(.plain)
    }
}

private struct HistoryPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)
            Text("히스토리 화면 준비 중")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    AppRootView()
}
