//
//  AppFonts.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/15/26.
//
// ==================================
// Figma 폰트 코드
// ==================================
import SwiftUI

enum AppFonts {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
}
