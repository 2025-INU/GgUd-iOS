//
//  WaitingRoomView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct WaitingRoomView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var showDepartureSheet = true
    @State private var myDeparture: String = ""
    @State private var myTransport: TransportType = .transit

    private let hostName = "혜림"

    //더미
    private let members: [WaitingMember] = [
        .init(name: "김민수 (나)", statusText: "위치 입력 완료", isDone: true),
        .init(name: "이윤", statusText: "위치 입력 대기중", isDone: false)
    ]

    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            // ✅ 기존 대기실 화면
            VStack(spacing: 0) {

                // Top Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColors.text)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }

                    Spacer()

                    Text("은석 생일")
                        .font(AppFonts.body(17))
                        .foregroundStyle(AppColors.text)
                        .padding(.top, 4)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)

                ScrollView {
                    WaitingRoomSummaryCard(
                        title: "은석 생일",
                        dateText: "2026-02-01",
                        timeText: "19:00",
                        subtitle: "약속이 생성되었습니다! 친구들을 초대해보세요."
                    )
                    .padding(.bottom, 6)

                    VStack(alignment: .leading, spacing: 16) {

                        // 1) 상단 요약 카드 (임시: 다음 단계에서 피그마대로 만들 예정)
                        // 우선 자리만 잡아두기
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.93, green: 0.97, blue: 1.0))
                            .frame(height: 150)

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

                        // 4) 하단 완료 박스 (임시 자리)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.green.opacity(0.12))
                            .frame(height: 120)

                        Spacer(minLength: 40)
                        
                        completionCTA
                            .padding(.top, 8)

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .scrollDismissesKeyboard(.interactively)

                Spacer()

                PrimaryButton(title: "중간 지점 찾기") {
                    print("중간 지점 찾기")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .disabled(showDepartureSheet) // ✅ 팝업 뜨면 뒤 터치 막기

            // ✅ 팝업(오버레이)
            if showDepartureSheet {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                DeparturePopupCard(
                    userName: hostName,
                    onConfirm: { departure, transport in
                        myDeparture = departure
                        myTransport = transport
                        showDepartureSheet = false
                    }
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
            }
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
                print("중간지점 확인하기")
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
