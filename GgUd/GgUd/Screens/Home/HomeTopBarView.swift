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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
