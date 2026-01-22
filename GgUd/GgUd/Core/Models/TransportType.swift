//
//  TransportType.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//

import Foundation

enum TransportType {
    case transit   // 대중교통
    case car
    case bike
}

extension TransportType {
    var displayText: String {
        switch self {
        case .transit: return "대중교통 이동"
        case .car:     return "차 이동"
        case .bike:    return "자전거 이동"
        }
    }
}

