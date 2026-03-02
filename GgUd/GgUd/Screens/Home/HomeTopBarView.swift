//
//  HomeTopBarView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct HomeTopBarView: View {

    var body: some View {
        HStack {
            Text("GgUd")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.text)

            Spacer()

            NavigationLink {
                NotificationView()
            } label: {
                HomeAlarmIcon()
                    .frame(width: 15, height: 18)
                    .overlay(alignment: .topTrailing) {
                        Text("2")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Color(hex: "#EF4444"))
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
