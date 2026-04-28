//
//  GgUdApp.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
#if canImport(KakaoMapsSDK)
import KakaoMapsSDK
#endif

@main
struct GgUdApp: App {
    @StateObject private var userSession = UserSessionStore()

    init() {
        KakaoSDK.initSDK(appKey: "5084e1974e29bdf05279f19629dadfcb")
#if canImport(KakaoMapsSDK)
        SDKInitializer.InitSDK(appKey: "5084e1974e29bdf05279f19629dadfcb")
#endif
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(userSession)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
