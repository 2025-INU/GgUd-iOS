
//
//  HomeAppointmentCard.swift
//  GgUd
//

//

import SwiftUI

public struct HomeAppointmentCard: View {
    let model: HomeAppointmentCardModel

    init(model: HomeAppointmentCardModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CardStyle.vStackSpacing) {
            header
            meta
            members
            location
        }
        .padding(CardStyle.padding)
        .background(cardBackground)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(model.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.88))
                .lineLimit(1)

            Spacer()

            StatusBadge(
                title: model.status.title,
                bg: model.status.background,
                fg: model.status.foreground
            )
        }
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: CardStyle.rowSpacing) {
            IconTextRow(systemName: "calendar", text: model.dateText)
            IconTextRow(systemName: "clock", text: model.timeText)
        }
    }

    private var members: some View {
        HStack(alignment: .center, spacing: CardStyle.memberRowSpacing) {
            OverlapAvatars(
                avatars: model.avatars,
                size: CardStyle.avatarSize,
                overlap: CardStyle.avatarOverlap
            )

            if !model.highlightInitials.isEmpty {
                FloatingInitialChips(initials: model.highlightInitials)
            }

            Spacer()

            Text(model.memberCountText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.60))
        }
        .padding(.top, 2)
    }

    private var location: some View {
        IconTextRow(systemName: "mappin.and.ellipse", text: model.locationText, weight: .semibold)
            .padding(.top, 2)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
            .fill(Color.white) // background: #FFFFFF
            .shadow(
                color: CardStyle.shadowColor,
                radius: CardStyle.shadowRadius,
                x: CardStyle.shadowX,
                y: CardStyle.shadowY
            )
            .overlay(
                RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                    .stroke(CardStyle.borderColor, lineWidth: CardStyle.borderWidth)
            )
    }

}

private struct StatusBadge: View {
    let title: String
    let bg: Color
    let fg: Color

    var body: some View {
        Text(title)
            .font(.system(size: CardStyle.badgeFontSize, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, CardStyle.badgeHPadding)
            .padding(.vertical, CardStyle.badgeVPadding)
            .background(Capsule().fill(bg))
    }
}

private struct FloatingInitialChips: View {
    let initials: [String]

    var body: some View {
        HStack(spacing: CardStyle.chipOverlapSpacing) {
            ForEach(Array(initials.prefix(2).enumerated()), id: \.offset) { idx, text in
                Text(text)
                    .font(.system(size: CardStyle.chipFontSize, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, CardStyle.chipHPadding)
                    .padding(.vertical, CardStyle.chipVPadding)
                    .background(
                        Capsule().fill(idx == 0
                                       ? Color(red: 0.13, green: 0.73, blue: 0.33)
                                       : Color(red: 0.46, green: 0.29, blue: 0.88))
                    )
                    .overlay(
                        Capsule().stroke(Color.white, lineWidth: CardStyle.chipBorderWidth)
                    )
                    .shadow(
                        color: Color.black.opacity(CardStyle.chipShadowOpacity),
                        radius: CardStyle.chipShadowRadius,
                        x: CardStyle.chipShadowX,
                        y: CardStyle.chipShadowY
                    )
            }
        }
    }
}

private struct IconTextRow: View {
    let systemName: String
    let text: String
    var weight: Font.Weight = .medium

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.45))
                .frame(width: 18)

            Text(text)
                .font(.system(size: 16, weight: weight))
                .foregroundStyle(Color.black.opacity(0.70))
                .lineLimit(1)
        }
    }
}


private struct OverlapAvatars: View {
    let avatars: [HomeAppointmentCardModel.Avatar]
    let size: CGFloat
    let overlap: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(avatars.prefix(4).enumerated()), id: \.offset) { idx, avatar in
                Circle()
                    .fill(avatar.color)
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.45, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.95))
                    )
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: CGFloat(idx) * (size - overlap))
            }
        }
        .frame(width: computedWidth, height: size)
    }

    private var computedWidth: CGFloat {
        let count = min(avatars.count, 4)
        guard count > 0 else { return 0 }
        return size + CGFloat(count - 1) * (size - overlap)
    }
}
