//
//  Appointment+HomeCard.swift
//  GgUd
//
//

import SwiftUI

extension Appointment {
    var homeCardModel: HomeAppointmentCardModel {
        HomeAppointmentCardModel(
            title: title,
            status: status == .ongoing ? .inProgress : .scheduled,
            dateText: dateText,
            timeText: timeText,
            locationText: locationText,
            avatars: memberColors.map { .init(color: $0) },
            highlightInitials: highlightInitials,
            memberCountText: "\(memberCount)명"
        )
    }
}
