//
//  CardStyle.swift
//  GgUd
//
//

import SwiftUI

enum CardStyle {

    // MARK: - Layout
    static let padding: CGFloat = 25
    static let cornerRadius: CGFloat = 16

    // MARK: - Border
    static let borderWidth: CGFloat = 1
    static let borderColor: Color = Color(red: 229/255, green: 231/255, blue: 235/255) // #E5E7EB

    // MARK: - Shadow (피그마 box-shadow)
    // box-shadow: 0px 1px 2px 0px #0000000D
    static let shadowColor: Color = Color.black.opacity(0.05) // 0D ≈ 5%
    static let shadowRadius: CGFloat = 2
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = 1

    // MARK: - Spacing
    static let vStackSpacing: CGFloat = 14
    static let rowSpacing: CGFloat = 10
    static let memberRowSpacing: CGFloat = 12

    // MARK: - Avatar
    static let avatarSize: CGFloat = 30
    static let avatarOverlap: CGFloat = 10

    // MARK: - Badge
    static let badgeFontSize: CGFloat = 13
    static let badgeHPadding: CGFloat = 12
    static let badgeVPadding: CGFloat = 7

    // MARK: - Initial Chip
    static let chipFontSize: CGFloat = 16
    static let chipHPadding: CGFloat = 12
    static let chipVPadding: CGFloat = 8
    static let chipOverlapSpacing: CGFloat = -6
    static let chipBorderWidth: CGFloat = 2

    static let chipShadowOpacity: Double = 0.10
    static let chipShadowRadius: CGFloat = 10
    static let chipShadowX: CGFloat = 0
    static let chipShadowY: CGFloat = 4
}
