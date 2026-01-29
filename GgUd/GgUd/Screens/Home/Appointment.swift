//
//  Appointment.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import SwiftUI

struct Appointment: Identifiable {
    let id = UUID()

    let title: String
    let status: Status
    let dateText: String
    let timeText: String
    let locationText: String

    let memberColors: [Color]       // 겹치는 아바타 색
    let highlightInitials: [String] // ["이","윤"]
    let memberCount: Int

    enum Status {
        case ongoing
        case scheduled
    }
}
