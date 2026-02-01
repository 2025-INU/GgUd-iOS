//
//  MyPageView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//

import SwiftUI

struct MyPageView: View {

    private let userName: String = "이은우"
    
    var body: some View {
            NavigationStack {
                content
            }
        }

    private var content: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // 1) 상단 바 (77 / padding 24-16-25 / bottom border #F3F4F6)
                MyPageTopBar(title: "마이페이지")

                // 2) 이름 칸 (129 / padding 32-24-33 / bottom border)
                MyPageNameSection(name: userName)

                // 3) 나머지 컨텐츠 (padding top 8, H16, bottom 96)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // 3-1 계정 그룹 (343w / bottom padding 24)
                        MyPageGroup {
                                    MyPageSectionLabel("계정")

                                    MyPageList {
                                        NavigationLink {
                                            ProfileEditView()
                                        } label: {
                                            MyPageListRow(title: "프로필 수정")
                                        }
                                        .buttonStyle(.plain)

                                        MyPageDivider()

                                        NavigationLink {
                                            NotificationSettingsView()
                                        } label: {
                                            MyPageListRow(title: "알림 설정")
                                        }
                                        .buttonStyle(.plain)

                                        MyPageDivider()

                                        Button {
                                            print("로그아웃")
                                        } label: {
                                            MyPageListRow(title: "로그아웃", isDestructive: true)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } // ✅ ✅ ✅ 계정 그룹 닫기
                                .padding(.bottom, MyPageStyle.groupSpacingBottom)
                        // 3-2 커뮤니티 그룹
                        MyPageGroup {
                            MyPageSectionLabel("커뮤니티")

                            MyPageList {
                                Button {
                                    print("친구 추가")
                                } label: {
                                    MyPageListRow(title: "친구 추가")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, MyPageStyle.groupSpacingBottom)

                        // 3-3 이용 안내 그룹
                        MyPageGroup {
                                    MyPageSectionLabel("이용 안내")

                                    MyPageList {
                                        Button {
                                            print("문의하기")
                                        } label: {
                                            MyPageListRow(title: "문의하기")
                                        }
                                        .buttonStyle(.plain)

                                        MyPageDivider()

                                        Button {
                                            print("이용약관")
                                        } label: {
                                            MyPageListRow(title: "이용약관")
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.bottom, MyPageStyle.groupSpacingBottom)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, MyPageStyle.contentPaddingTop)
                    .padding(.horizontal, MyPageStyle.contentPaddingH)
                    .padding(.bottom, MyPageStyle.contentPaddingBottom)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Top Bar

private struct MyPageTopBar: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.text)
                Spacer()
            }
            .padding(.top, MyPageStyle.topBarPaddingTop)
            .padding(.horizontal, MyPageStyle.topBarPaddingH)
            .padding(.bottom, MyPageStyle.topBarPaddingBottom)
            .frame(height: MyPageStyle.topBarHeight, alignment: .bottom)

            Rectangle()
                .fill(AppColors.divider)
                .frame(height: MyPageStyle.dividerHeight)
        }
        .background(Color.white)
    }
}

// MARK: - Name Section

private struct MyPageNameSection: View {
    let name: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.gray.opacity(0.7))
                    )

                Text(name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Spacer()
            }
            .padding(.top, MyPageStyle.nameSectionPaddingTop)
            .padding(.horizontal, MyPageStyle.nameSectionPaddingH)
            .padding(.bottom, MyPageStyle.nameSectionPaddingBottom)
            .frame(height: MyPageStyle.nameSectionHeight, alignment: .center)

            Rectangle()
                .fill(AppColors.divider)
                .frame(height: MyPageStyle.dividerHeight)
        }
        .background(Color.white)
    }
}

// MARK: - Content Building Blocks

private struct MyPageGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MyPageSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.subText)
            .padding(.leading, 2)
    }
}

private struct MyPageList<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1) // 필요하면 border로 바꿔도 됨
        )
        .frame(maxWidth: .infinity)
    }
}

private struct MyPageListRow: View {
    let title: String
    var isDestructive: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isDestructive ? Color.red : AppColors.text)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.subText)
        }
        .padding(.top, 16)
        .padding(.bottom, 17)
        .padding(.horizontal, 16)
        .frame(height: 61, alignment: .center)
        .contentShape(Rectangle()) // ✅ 탭 영역 확보
    }
}

private struct MyPageDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: 1)
    }
}
