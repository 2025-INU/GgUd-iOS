//
//  MidpointView.swift
//  GgUd
//
//

import SwiftUI

struct MidpointView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isSheetExpanded: Bool = false
    @GestureState private var dragOffset: CGFloat = 0

    private let participants: [MarkerItem] = [
        .init(title: "김민수", icon: "person.fill", color: Color(red: 0.97, green: 0.36, blue: 0.35)),
        .init(title: "이지은", icon: "person.fill", color: Color(red: 0.23, green: 0.52, blue: 0.98)),
        .init(title: "박준호", icon: "person.fill", color: Color(red: 0.21, green: 0.78, blue: 0.43)),
        .init(title: "최수영", icon: "person.fill", color: Color(red: 0.65, green: 0.44, blue: 0.96)),
        .init(title: "정민재", icon: "person.fill", color: Color(red: 0.95, green: 0.68, blue: 0.08))
    ]

    private let recommendations: [PlaceItem] = [
        .init(title: "강남역 4번 출구 근처", address: "서울특별시 강남구 강남대로 396", timeText: "평균 12분"),
        .init(title: "역삼역 2번 출구 근처", address: "서울특별시 강남구 테헤란로 123", timeText: "평균 15분")
    ]

    private let participantPoints: [CGPoint] = [
        .init(x: 0.18, y: 0.28),
        .init(x: 0.42, y: 0.42),
        .init(x: 0.32, y: 0.56),
        .init(x: 0.62, y: 0.64),
        .init(x: 0.74, y: 0.52)
    ]

    private let midpointPoints: [CGPoint] = [
        .init(x: 0.55, y: 0.60),
        .init(x: 0.70, y: 0.70)
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                GeometryReader { proxy in
                    let height = proxy.size.height
                    let sheetHeight = min(420, height * 0.62)
                    let collapsedY = height - 160
                    let expandedY = height - sheetHeight
                    let baseY = isSheetExpanded ? expandedY : collapsedY

                    ZStack(alignment: .topLeading) {
                        mapPlaceholder
                            .frame(width: proxy.size.width, height: proxy.size.height)

                        participantsCard
                            .padding(.top, 20)
                            .padding(.leading, 24)

                        infoCard
                            .padding(.top, 12)
                            .padding(.horizontal, 24)

                        bottomSheet
                            .frame(width: proxy.size.width, height: sheetHeight, alignment: .top)
                            .offset(y: baseY + dragOffset)
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.height
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 80
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        if value.translation.height < -threshold {
                                            isSheetExpanded = true
                                        } else if value.translation.height > threshold {
                                            isSheetExpanded = false
                                        }
                                    }
                                }
                        )
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text("중간지점 결과")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .padding(.leading, 24)
        .padding(.top, 16)
        .padding(.bottom, 17)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
    }

    private var mapPlaceholder: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.94, green: 0.95, blue: 0.97))

                ForEach(Array(participants.enumerated()), id: \.offset) { index, item in
                    marker(item)
                        .position(
                            x: geo.size.width * participantPoints[index % participantPoints.count].x,
                            y: geo.size.height * participantPoints[index % participantPoints.count].y
                        )
                }

                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, _ in
                    marker(.init(title: "추천", icon: "mappin", color: Color(red: 0.22, green: 0.62, blue: 0.96)))
                        .position(
                            x: geo.size.width * midpointPoints[index % midpointPoints.count].x,
                            y: geo.size.height * midpointPoints[index % midpointPoints.count].y
                        )
                }
            }
        }
    }

    private var infoCard: some View {
        VStack(spacing: 8) {
            Text("모이기 좋은 장소를 선택하세요")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("모든 참여자의 위치를 고려한 최적의 중간지점이에요")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.subText)

            Image(systemName: "person.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.subText)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 15, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
    }

    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)

            Text("추천 중간지점")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            ForEach(recommendations) { item in
                placeCard(item)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
    }

    private var participantsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("참여자")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.text)

            ForEach(participants) { item in
                HStack(spacing: 10) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 22, height: 22)

                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
    private func marker(_ item: MarkerItem) -> some View {
        ZStack {
            Circle()
                .fill(item.color)
                .frame(width: 44, height: 44)

            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func placeCard(_ item: PlaceItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Text(item.address)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.subText)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                    Text(item.timeText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }

            Spacer()

            Circle()
                .fill(Color(red: 0.90, green: 0.96, blue: 1.0))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                )
        }
        .padding(14)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

private struct MarkerItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

private struct PlaceItem: Identifiable {
    let id = UUID()
    let title: String
    let address: String
    let timeText: String
}

#Preview {
    MidpointView()
}
