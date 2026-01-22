//
//  HomeTopBarView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct HomeTopBarView: View {
    let onTapBell: () -> Void

    var body: some View {
        HStack {
            Text("로고")
                .font(AppFonts.title(20))
                .foregroundStyle(AppColors.text)

            Spacer()

            Button(action: onTapBell) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.text)
                    .padding(8)
            }
        }
    }
}
