//
//  KkodleTheme.swift
//  Kkodle
//
//  Created by 장주진 on 9/19/26.
//

import SwiftUI
import UIKit

/// Shared pastel design tokens (colors, card shape) for a playful,
/// non-corporate feel — used across the home screen and, eventually, the
/// game screens, so the look stays consistent without hardcoding colors
/// in every view.
enum KkodleTheme {
    static let background = Color(
        light: Color(red: 1.0, green: 0.97, blue: 0.92),
        dark: Color(red: 0.11, green: 0.10, blue: 0.09)
    )

    static let cardCornerRadius: CGFloat = 20
    static let cardShadow = Color.black.opacity(0.08)

    /// Each game mode gets its own pastel identity, so the mode list reads
    /// as a set of distinct choices rather than a stack of identical rows.
    enum ModeAccent {
        case daily, endless, timeAttack, battle

        var fill: Color {
            switch self {
            case .daily:
                Color(light: Color(red: 1.0, green: 0.85, blue: 0.84), dark: Color(red: 0.32, green: 0.18, blue: 0.18))
            case .endless:
                Color(light: Color(red: 0.82, green: 0.96, blue: 0.89), dark: Color(red: 0.12, green: 0.26, blue: 0.20))
            case .timeAttack:
                Color(light: Color(red: 1.0, green: 0.94, blue: 0.76), dark: Color(red: 0.30, green: 0.25, blue: 0.10))
            case .battle:
                Color(light: Color(red: 0.89, green: 0.87, blue: 1.0), dark: Color(red: 0.22, green: 0.18, blue: 0.34))
            }
        }

        var accent: Color {
            switch self {
            case .daily: Color(red: 0.90, green: 0.40, blue: 0.38)
            case .endless: Color(red: 0.18, green: 0.60, blue: 0.42)
            case .timeAttack: Color(red: 0.78, green: 0.56, blue: 0.10)
            case .battle: Color(red: 0.47, green: 0.38, blue: 0.86)
            }
        }
    }
}

extension Color {
    /// A color that switches between two fixed values by interface style,
    /// without needing an asset-catalog color set for each design token.
    init(light: Color, dark: Color) {
        self = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

/// Scales a button down slightly while pressed, so the custom keyboard/submit
/// buttons feel tactile instead of static — SwiftUI's plain button style
/// gives no press feedback at all on its own.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
