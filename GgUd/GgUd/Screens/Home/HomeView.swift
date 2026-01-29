import SwiftUI

struct HomeView: View {

    // 임시 데이터(나중에 API/DB 붙이면 ViewModel/Store로 이동)
    private let ongoing: [Appointment] = [
        Appointment(
            title: "회사 동료 점심 모임",
            status: .ongoing,
            dateText: "2025-11-10",
            timeText: "12:30",
            locationText: "강남역 4번 출구 근처",
            memberColors: [.red, .blue, .green, .purple],
            highlightInitials: ["이", "윤"],
            memberCount: 4
        )
    ]

    private let scheduled: [Appointment] = [
        Appointment(
            title: "동아리 회의",
            status: .scheduled,
            dateText: "2025-11-15",
            timeText: "19:00",
            locationText: "인천대 정문 카페",
            memberColors: [.orange, .pink, .blue],
            highlightInitials: ["김", "박"],
            memberCount: 3
        )
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HomeTopBarView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        // 진행중 약속
                        Text("진행중 약속")
                            .font(AppFonts.body(14))
                            .foregroundStyle(AppColors.text)
                            .padding(.top, 8)

                        ForEach(ongoing) { item in
                            HomeAppointmentCard(model: item.homeCardModel)
                        }

                        // 예정된 약속
                        Text("예정된 약속")
                            .font(AppFonts.body(14))
                            .foregroundStyle(AppColors.text)
                            .padding(.top, 10)

                        ForEach(scheduled) { item in
                            HomeAppointmentCard(model: item.homeCardModel)
                        }

                        Spacer(minLength: 80) // 탭바 공간
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .bottomTrailing) {
            NavigationLink {
                CreateAppointmentView()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(AppColors.primary)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
    }
}
