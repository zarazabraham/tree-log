//
//  DesignSystem.swift
//  Plantydex Design System
//
//  Single import point for the entire design system.
//  Import this file to get access to all design system components and tokens.
//

import SwiftUI

// This file serves as a validation that all design system components compile together.
// It also provides a single import point if needed.

// MARK: - Design System Validation

#if DEBUG
struct DesignSystemValidator {
    static func validate() {
        // Tokens
        let _ = ColorTokens.fallback
        let _ = TypographyTokens()
        let _ = SpacingTokens()
        let _ = RadiiTokens()
        let _ = ElevationTokens()
        let _ = MotionTokens()

        // Theme
        let _ = Theme.default

        print("✅ Design System validated successfully")
    }
}
#endif
