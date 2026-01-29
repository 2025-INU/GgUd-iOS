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

            Button {
                // 알림 화면 이동 (나중에)
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.text)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
