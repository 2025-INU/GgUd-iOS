//
//  GgUdApp.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct GgUdApp: App {
    init() {
        KakaoSDK.initSDK(appKey: "a0773999bd309278a1ab955b9b21fb0b")
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
