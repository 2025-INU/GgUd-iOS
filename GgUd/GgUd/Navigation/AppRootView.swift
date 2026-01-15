//
//  AppRootView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//

import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("홈", systemImage: "house") }

            NavigationStack {
                MapView()
            }
            .tabItem { Label("지도", systemImage: "map") }

            NavigationStack {
                MyPageView()
            }
            .tabItem { Label("마이페이지", systemImage: "person") }
        }
    }
}

