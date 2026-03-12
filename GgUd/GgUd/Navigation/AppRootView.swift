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
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
