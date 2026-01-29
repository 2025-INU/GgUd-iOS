//
//  HomeAppointmentCardModel.swift
//  GgUd
//
//

import SwiftUI

struct HomeAppointmentCardModel {

    enum Status {
        case inProgress
        case scheduled

        var title: String {
            switch self {
            case .inProgress: return "진행중"
            case .scheduled:  return "예정"
            }
        }

        var background: Color {
            switch self {
            case .inProgress:
                return Color(red: 0.86, green: 0.97, blue: 0.89) // 연초록
            case .scheduled:
                return Color(red: 0.90, green: 0.93, blue: 1.00) // 연파랑
            }
        }

        var foreground: Color {
            switch self {
            case .inProgress:
                return Color(red: 0.09, green: 0.55, blue: 0.28)
            case .scheduled:
                return Color(red: 0.10, green: 0.35, blue: 0.85)
            }
        }
    }

    struct Avatar {
        let color: Color
    }

    let title: String
    let status: Status
    let dateText: String
    let timeText: String
    let locationText: String

    let avatars: [Avatar]
    let highlightInitials: [String]
    let memberCountText: String
}
