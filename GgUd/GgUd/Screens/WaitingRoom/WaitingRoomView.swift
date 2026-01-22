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

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)

                ScrollView {
                    VStack(spacing: 12) {

                        // ✅ 지금은 방장 1명만
                        WaitingMemberCard(
                            name: hostName,
                            location: myDeparture.isEmpty ? "출발지 입력 중" : myDeparture,
                            transport: myTransport
                        )

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
}
