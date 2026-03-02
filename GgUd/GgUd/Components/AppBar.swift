//
//  AppBar.swift
//  GgUd
//
//

import SwiftUI

struct AppBar: View {
    let title: String
    let subtitle: String?
    let onBack: () -> Void

    init(title: String, subtitle: String? = nil, onBack: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
    }

    private enum A {
        static let height: CGFloat = 69
        static let padTop: CGFloat = 16
        static let padH: CGFloat = 24
        static let padBottom: CGFloat = 17
        static let border: CGFloat = 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.subText)
                    }
                }

                Spacer()
            }
            .padding(.top, A.padTop)
            .padding(.horizontal, A.padH)
            .padding(.bottom, A.padBottom)
            .frame(height: A.height)

            Rectangle()
                .fill(Color(hex: "#E5E7EB"))
                .frame(height: A.border)
        }
        .background(Color.white)
    }
}

#Preview {
    AppBar(title: "정산하기", subtitle: "친구들과 카페 모임", onBack: {})
}
