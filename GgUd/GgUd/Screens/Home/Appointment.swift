//
//  Appointment.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import Foundation

enum AppointmentStatus {
    case ongoing
    case scheduled
}

struct Appointment: Identifiable {
    let id = UUID()
    let title: String
    let members: [String]
    let dateText: String
    let status: AppointmentStatus
    let badgeText: String?   // 예: "경로"
}
