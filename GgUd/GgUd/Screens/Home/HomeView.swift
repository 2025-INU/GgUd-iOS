//
//  HomeView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//
import SwiftUI

struct HomeView: View {

    // 임시 데이터(나중에 API/DB 붙이면 ViewModel/Store로 이동)
    private let ongoing: [Appointment] = [
        Appointment(
            title: "은우 생일 (부평역)",
            members: ["이은우", "윤은석", "정철웅"],
            dateText: "9월 29일",
            status: .ongoing,
            badgeText: "경로"
        )
    ]

    private let scheduled: [Appointment] = [
        Appointment(
            title: "은우 생일 (부평역)",
            members: ["이은우", "윤은석", "정철웅"],
            dateText: "9월 29일",
            status: .scheduled,
            badgeText: nil
        ),
        Appointment(
            title: "은우 생일 (부평역)",
            members: ["이은우", "윤은석", "정철웅"],
            dateText: "9월 29일",
            status: .scheduled,
            badgeText: nil
        )
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    HomeTopBarView(onTapBell: {
                        print("알림")
                    })
                    .padding(.top, 8)

                    // 중앙 CTA (push 이동)
                    HStack {
                        Spacer()

                        NavigationLink {
                            CreateAppointmentView()
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
                    .padding(.vertical, 14)

                    // 진행중 약속
                    Text("진행중 약속")
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.text)

                    ForEach(ongoing) { item in
                        AppointmentCard(item: item)
                    }

                    // 예정된 약속
                    Text("예정된 약속")
                        .font(AppFonts.body(14))
                        .foregroundStyle(AppColors.text)
                        .padding(.top, 10)

                    ForEach(scheduled) { item in
                        AppointmentCard(item: item)
                    }

                    Spacer(minLength: 80) // 탭바 공간
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }
}
