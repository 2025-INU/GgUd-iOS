import SwiftUI

struct HomeView: View {
    fileprivate enum HomeSegment {
        case ongoing
        case scheduled
    }

    @State private var selectedSegment: HomeSegment = .ongoing

    private let ongoing: [HomePromise] = [
        .init(title: "대학 동기 모임", date: "2024-12-15", time: "19:00", people: 4, place: "강남역 4번 출구 근처", statusText: "진행중", confirmedPlace: nil),
        .init(title: "팀 프로젝트 회의", date: "2024-12-16", time: "14:00", people: 4, place: "선릉역 스터디룸", statusText: "진행중", confirmedPlace: nil)
    ]

    private let scheduled: [HomePromise] = [
        .init(title: "생일 파티", date: "2024-12-20", time: "18:00", people: 3, place: "역삼역 2번 출구 근처", statusText: "확정", confirmedPlace: "루프탑 바 스카이"),
        .init(title: "저녁 약속", date: "2024-12-22", time: "19:30", people: 6, place: "강남역 맛집", statusText: "확정", confirmedPlace: "모던 이탈리안 키친"),
        .init(title: "영화 모임", date: "2024-12-24", time: "20:00", people: 4, place: "삼성역 코엑스", statusText: "확정", confirmedPlace: "CGV 코엑스")
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                HomeTopBarView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HomeSegmentedSwitch(selected: $selectedSegment)
                            .padding(.top, 12)
                            .padding(.horizontal, 24)

                        VStack(spacing: 16) {
                            ForEach(selectedSegment == .ongoing ? ongoing : scheduled) { item in
                                CardContent(item: item, isScheduled: selectedSegment == .scheduled)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .bottomTrailing) {
            NavigationLink {
                CreateAppointmentView()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#3B82F6"), Color(hex: "#2563EB")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 28)
            .padding(.bottom, 108)
        }
    }
}

private struct HomeSegmentedSwitch: View {
    @Binding var selected: HomeView.HomeSegment

    var body: some View {
        HStack(spacing: 0) {
            segment(title: "진행중인 약속", selected: selected == .ongoing) {
                selected = .ongoing
            }
            segment(title: "예정된 약속", selected: selected == .scheduled) {
                selected = .scheduled
            }
        }
        .padding(4)
        .background(Color(hex: "#F3F4F6"))
        .clipShape(Capsule())
    }

    private func segment(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selected ? Color.white : Color(hex: "#4B5563"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    selected
                    ? LinearGradient(
                        colors: [Color(hex: "#3B82F6"), Color(hex: "#2563EB")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
