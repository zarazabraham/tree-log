//
//  ElevationTokens.swift
//  Plantydex Design System
//
//  Shadow and elevation tokens for layering and depth.
//

import SwiftUI

/// Elevation tokens for consistent shadows and depth.
struct ElevationTokens {

    // MARK: - Shadow Configurations

    /// No elevation - flat on surface
    let none = ShadowConfig(radius: 0, x: 0, y: 0, opacity: 0)

    /// Level 1 - Subtle elevation (chips, small cards)
    let level1 = ShadowConfig(radius: 2, x: 0, y: 1, opacity: 0.08)

    /// Level 2 - Low elevation (buttons, input fields)
    let level2 = ShadowConfig(radius: 4, x: 0, y: 2, opacity: 0.1)

    /// Level 3 - Medium elevation (cards, containers)
    let level3 = ShadowConfig(radius: 8, x: 0, y: 4, opacity: 0.12)

    /// Level 4 - High elevation (dropdowns, popovers)
    let level4 = ShadowConfig(radius: 16, x: 0, y: 8, opacity: 0.14)

    /// Level 5 - Very high elevation (modals, dialogs)
    let level5 = ShadowConfig(radius: 24, x: 0, y: 12, opacity: 0.16)
}

/// Configuration for a shadow effect
struct ShadowConfig {
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    let color: Color

    init(
        radius: CGFloat,
        x: CGFloat,
        y: CGFloat,
        opacity: Double,
        color: Color = .black
    ) {
        self.radius = radius
        self.x = x
        self.y = y
        self.opacity = opacity
        self.color = color
    }
}

// MARK: - View Extensions for Elevation

extension View {
    /// Apply elevation shadow using elevation tokens
    func elevation(_ level: ElevationLevel) -> some View {
        self.modifier(ElevationModifier(level: level))
    }
}

/// Elevation levels that can be used throughout the app
enum ElevationLevel {
    case none
    case level1
    case level2
    case level3
    case level4
    case level5
    case custom(ShadowConfig)

    var config: ShadowConfig {
        let tokens = ElevationTokens()
        switch self {
        case .none: return tokens.none
        case .level1: return tokens.level1
        case .level2: return tokens.level2
        case .level3: return tokens.level3
        case .level4: return tokens.level4
        case .level5: return tokens.level5
        case .custom(let config): return config
        }
    }
}

private struct ElevationModifier: ViewModifier {
    let level: ElevationLevel

    func body(content: Content) -> some View {
        let config = level.config
        return content.shadow(
            color: config.color.opacity(config.opacity),
            radius: config.radius,
            x: config.x,
            y: config.y
        )
    }
}
