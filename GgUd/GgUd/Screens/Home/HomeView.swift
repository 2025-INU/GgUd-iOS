//
//  HomeView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//
import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // 상단 바: 로고 / 알림
                    HStack {
                        Text("로고")
                            .font(AppFonts.title(20))
                            .foregroundStyle(AppColors.text)

                        Spacer()

                        Button {
                            print("알림")
                        } label: {
                            Image(systemName: "bell")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(AppColors.text)
                                .padding(8)
                        }
                    }
                    .padding(.top, 8)

                    // 중앙 큰 버튼(약속 만들기)
                    HStack {
                        Spacer()
                        Button {
                            print("약속 만들기")
                        } label: {
                            Text("약속 만들기")
                                .font(AppFonts.body(16))
                                .foregroundStyle(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 36)
                                .background(AppColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 6)

                    // 진행중 약속 섹션
                    Text("진행중 약속")
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.text)

                    AppointmentCard(
                        title: "은우 생일 (부평역)",
                        members: "이은우, 윤은석, 정철웅",
                        dateText: "9월 29일",
                        badgeText: "경로"
                    )

                    // 예정된 약속 섹션
                    Text("예정된 약속")
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.text)
                        .padding(.top, 10)

                    AppointmentCard(
                        title: "은우 생일 (부평역)",
                        members: "이은우, 윤은석, 정철웅",
                        dateText: "9월 29일",
                        badgeText: nil
                    )

                    AppointmentCard(
                        title: "은우 생일 (부평역)",
                        members: "이은우, 윤은석, 정철웅",
                        dateText: "9월 29일",
                        badgeText: nil
                    )

                    Spacer(minLength: 80) // 탭바 공간 확보
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true) // 상단 네비 타이틀 숨김(이미지처럼)
    }
}
