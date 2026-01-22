//
//  DeparturePopupCard.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct DeparturePopupCard: View {

    let userName: String
    let onConfirm: (_ departure: String, _ transport: TransportType) -> Void

    @State private var keyword: String = ""
    @State private var transport: TransportType = .transit

    var body: some View {
        VStack(spacing: 16) {

            Text("\(userName) 님,\n어디서 출발 하시나요?")
                .multilineTextAlignment(.center)
                .font(AppFonts.body(16))
                .foregroundStyle(AppColors.text)

            // 검색창(임시)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.subText)

                TextField("Search", text: $keyword)
                    .textInputAutocapitalization(.never)

                Spacer()

                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(AppColors.subText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // 교통수단 선택
            HStack(spacing: 12) {
                TransportButton(title: "대중교통", isSelected: transport == .transit) {
                    transport = .transit
                }
                TransportButton(title: "차", isSelected: transport == .car) {
                    transport = .car
                }
                TransportButton(title: "자전거", isSelected: transport == .bike) {
                    transport = .bike
                }
            }


            Button {
                let dep = keyword.isEmpty ? "출발지 미입력" : keyword
                onConfirm(dep, transport)
            } label: {
                Text("약속 참여")
                    .font(AppFonts.body(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(radius: 12)
    }
}

