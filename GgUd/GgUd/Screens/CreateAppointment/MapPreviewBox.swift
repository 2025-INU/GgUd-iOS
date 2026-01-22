//
//  MapPreviewBox.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct MapPreviewBox: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.05))
            .frame(height: 220)
            .overlay(
                Image(systemName: "map")
                    .font(.system(size: 32))
                    .foregroundStyle(.gray)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
