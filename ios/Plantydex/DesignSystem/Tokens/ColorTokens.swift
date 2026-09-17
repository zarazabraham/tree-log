//
//  ColorTokens.swift
//  Plantydex Design System
//
//  Semantic color tokens that support light and dark modes.
//

import SwiftUI

/// Semantic color tokens for the Plantydex design system.
/// All colors adapt automatically to light/dark mode.
struct ColorTokens {

    // MARK: - Brand Colors

    /// Primary brand color (green) - used for primary actions and key UI elements
    let primary: Color

    /// Secondary brand color - used for secondary actions
    let secondary: Color

    // MARK: - Neutral Colors

    /// Surface colors for backgrounds and cards
    let surfacePrimary: Color
    let surfaceSecondary: Color
    let surfaceTertiary: Color

    // MARK: - Text Colors

    /// Text hierarchy colors
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    /// Text on colored backgrounds
    let textOnPrimary: Color
    let textOnSecondary: Color

    // MARK: - Semantic Colors

    /// Success state color
    let success: Color
    let successSubdued: Color

    /// Error state color
    let error: Color
    let errorSubdued: Color

    /// Warning state color
    let warning: Color
    let warningSubdued: Color

    /// Info state color
    let info: Color
    let infoSubdued: Color

    // MARK: - Border Colors

    let borderPrimary: Color
    let borderSecondary: Color

    // MARK: - Initializers

    /// Default initializer attempts to use asset catalog colors
    init() {
        self.primary = Color("Primary", bundle: .main)
        self.secondary = Color("Secondary", bundle: .main)
        self.surfacePrimary = Color("SurfacePrimary", bundle: .main)
        self.surfaceSecondary = Color("SurfaceSecondary", bundle: .main)
        self.surfaceTertiary = Color("SurfaceTertiary", bundle: .main)
        self.textPrimary = Color("TextPrimary", bundle: .main)
        self.textSecondary = Color("TextSecondary", bundle: .main)
        self.textTertiary = Color("TextTertiary", bundle: .main)
        self.textOnPrimary = Color("TextOnPrimary", bundle: .main)
        self.textOnSecondary = Color("TextOnSecondary", bundle: .main)
        self.success = Color("Success", bundle: .main)
        self.successSubdued = Color("SuccessSubdued", bundle: .main)
        self.error = Color("Error", bundle: .main)
        self.errorSubdued = Color("ErrorSubdued", bundle: .main)
        self.warning = Color("Warning", bundle: .main)
        self.warningSubdued = Color("WarningSubdued", bundle: .main)
        self.info = Color("Info", bundle: .main)
        self.infoSubdued = Color("InfoSubdued", bundle: .main)
        self.borderPrimary = Color("BorderPrimary", bundle: .main)
        self.borderSecondary = Color("BorderSecondary", bundle: .main)
    }

    /// Custom initializer for fallback colors
    init(
        primary: Color,
        secondary: Color,
        surfacePrimary: Color,
        surfaceSecondary: Color,
        surfaceTertiary: Color,
        textPrimary: Color,
        textSecondary: Color,
        textTertiary: Color,
        textOnPrimary: Color,
        textOnSecondary: Color,
        success: Color,
        successSubdued: Color,
        error: Color,
        errorSubdued: Color,
        warning: Color,
        warningSubdued: Color,
        info: Color,
        infoSubdued: Color,
        borderPrimary: Color,
        borderSecondary: Color
    ) {
        self.primary = primary
        self.secondary = secondary
        self.surfacePrimary = surfacePrimary
        self.surfaceSecondary = surfaceSecondary
        self.surfaceTertiary = surfaceTertiary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.textOnPrimary = textOnPrimary
        self.textOnSecondary = textOnSecondary
        self.success = success
        self.successSubdued = successSubdued
        self.error = error
        self.errorSubdued = errorSubdued
        self.warning = warning
        self.warningSubdued = warningSubdued
        self.info = info
        self.infoSubdued = infoSubdued
        self.borderPrimary = borderPrimary
        self.borderSecondary = borderSecondary
    }

    // MARK: - Fallback Implementation
    // If asset catalog colors are not available, use these as fallbacks

    static let fallback = ColorTokens(
        primary: .green,
        secondary: .gray,
        surfacePrimary: Color(.systemBackground),
        surfaceSecondary: Color(.secondarySystemBackground),
        surfaceTertiary: Color(.tertiarySystemBackground),
        textPrimary: Color(.label),
        textSecondary: Color(.secondaryLabel),
        textTertiary: Color(.tertiaryLabel),
        textOnPrimary: .white,
        textOnSecondary: .white,
        success: .green,
        successSubdued: Color.green.opacity(0.1),
        error: .red,
        errorSubdued: Color.red.opacity(0.1),
        warning: .orange,
        warningSubdued: Color.orange.opacity(0.1),
        info: .blue,
        infoSubdued: Color.blue.opacity(0.1),
        borderPrimary: Color(.separator),
        borderSecondary: Color(.separator).opacity(0.3)
    )
}
