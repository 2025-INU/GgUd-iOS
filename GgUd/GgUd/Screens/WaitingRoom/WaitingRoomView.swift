//
//  WaitingRoomView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct WaitingRoomView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var showDepartureSheet = false
    @State private var navigateToMidpoint: Bool = false

    // 더미
    private let members: [WaitingMember] = [
        .init(name: "김민수 (나)", statusText: "위치 입력 완료", isDone: true),
        .init(name: "이지은", statusText: "위치 입력 완료", isDone: true),
        .init(name: "박준호", statusText: "위치 입력 완료", isDone: true),
        .init(name: "최수영", statusText: "위치 입력 완료", isDone: true),
        .init(name: "정민재", statusText: "위치 입력 완료", isDone: true)
    ]

    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            // ✅ 기존 대기실 화면
            VStack(spacing: 0) {

                AppBar(title: "약속 대기방", onBack: { dismiss() })

                ScrollView {
                    WaitingRoomSummaryCard(
                        title: "대학 동기 모임",
                        dateText: "2025-11-28",
                        timeText: "19:52",
                        subtitle: "약속이 생성되었습니다!"
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 16) {

                        // 2) 친구 초대하기 섹션 (임시 자리)
                        Text("친구 초대하기")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        KakaoShareButton {
                            print("카카오 공유 탭")
                        }

                        Text("링크를 통해 친구들이 약속에 참여할 수 있어요")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.subText)

                        // 3) 참여한 친구
                        HStack {
                            Text("참여한 친구")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppColors.text)

                            Spacer()

                            Text("\(members.count)명")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                        }
                        .padding(.top, 12)

                        ForEach(members) { m in
                            WaitingMemberRowCard(member: m)   // 새 피그마 카드
                        }

                        completionCTA
                            .padding(.top, 8)

                        NavigationLink(
                            destination: MidpointView(),
                            isActive: $navigateToMidpoint
                        ) {
                            EmptyView()
                        }
                        .hidden()

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)

                Spacer()
            }
            .disabled(showDepartureSheet) // ✅ 팝업 뜨면 뒤 터치 막기
        }
        .animation(.easeInOut(duration: 0.2), value: showDepartureSheet)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var allMembersDone: Bool {
        members.allSatisfy { $0.isDone }
    }

    private var completionCTA: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("모든 참여자가 위치를 입력했습니다!")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(red: 22/255, green: 163/255, blue: 74/255)) // 초록 텍스트

            Button {
                navigateToMidpoint = true
            } label: {
                Text("중간지점 확인하기")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(red: 22/255, green: 163/255, blue: 74/255)) // 진초록
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!allMembersDone)
            .opacity(allMembersDone ? 1 : 0.45)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 220/255, green: 252/255, blue: 231/255)) // 연한 초록 배경
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 134/255, green: 239/255, blue: 172/255), lineWidth: 1) // 연한 초록 테두리
        )
    }

}
