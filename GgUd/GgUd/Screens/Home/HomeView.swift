import SwiftUI

struct HomeView: View {
    fileprivate enum HomeSegment {
        case ongoing
        case scheduled
    }

    @State private var selectedSegment: HomeSegment = .ongoing

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
                        HomeSegmentedSwitch(selected: $selectedSegment)
                            .padding(.top, 8)

                        Group {
                            switch selectedSegment {
                            case .ongoing:
                                ForEach(ongoing) { item in
                                    HomeAppointmentCard(model: item.homeCardModel)
                                }
                            case .scheduled:
                                ForEach(scheduled) { item in
                                    HomeAppointmentCard(model: item.homeCardModel)
                                }
                            }
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
            .padding(.bottom, 110)
        }
        .overlay(alignment: .bottomLeading) {
            NavigationLink {
                LoginView()
            } label: {
                Text("로그인 (임시)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.subText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(AppColors.border.opacity(0.6), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.bottom, 110)
        }
    }
}

private struct HomeSegmentedSwitch: View {
    @Binding var selected: HomeView.HomeSegment

    private let accent = AppColors.primary
    private let background = Color(red: 0.94, green: 0.95, blue: 0.97)
    private let unselectedText = Color(red: 0.42, green: 0.45, blue: 0.50)

    var body: some View {
        HStack(spacing: 0) {
            segmentButton(title: "진행중인 약속", isSelected: selected == .ongoing) {
                selected = .ongoing
            }
            segmentButton(title: "예정된 약속", isSelected: selected == .scheduled) {
                selected = .scheduled
            }
        }
        .padding(4)
        .background(background)
        .clipShape(Capsule())
    }

    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.body(14))
                .foregroundStyle(isSelected ? Color.white : unselectedText)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? accent : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
