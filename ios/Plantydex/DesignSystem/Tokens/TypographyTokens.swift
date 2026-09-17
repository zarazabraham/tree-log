//
//  TypographyTokens.swift
//  Plantydex Design System
//
//  Semantic typography tokens that support Dynamic Type.
//

import SwiftUI

/// Semantic typography tokens for the Plantydex design system.
/// All text styles support Dynamic Type for accessibility.
struct TypographyTokens {

    // MARK: - Display Styles

    /// Large display text (navigation titles, hero text)
    let displayLarge = Font.system(.largeTitle, design: .default, weight: .bold)
    let displayMedium = Font.system(.title, design: .default, weight: .bold)
    let displaySmall = Font.system(.title2, design: .default, weight: .bold)

    // MARK: - Heading Styles

    /// Section headings and card titles
    let headingLarge = Font.system(.title3, design: .default, weight: .semibold)
    let headingMedium = Font.system(.headline, design: .default, weight: .semibold)
    let headingSmall = Font.system(.subheadline, design: .default, weight: .semibold)

    // MARK: - Body Styles

    /// Main body text
    let bodyLarge = Font.system(.body, design: .default, weight: .regular)
    let bodyMedium = Font.system(.callout, design: .default, weight: .regular)
    let bodySmall = Font.system(.subheadline, design: .default, weight: .regular)

    /// Emphasized body text
    let bodyLargeEmphasized = Font.system(.body, design: .default, weight: .medium)
    let bodyMediumEmphasized = Font.system(.callout, design: .default, weight: .medium)

    // MARK: - Caption Styles

    /// Secondary informational text, labels
    let captionLarge = Font.system(.footnote, design: .default, weight: .regular)
    let captionMedium = Font.system(.caption, design: .default, weight: .regular)
    let captionSmall = Font.system(.caption2, design: .default, weight: .regular)

    /// Emphasized captions
    let captionLargeEmphasized = Font.system(.footnote, design: .default, weight: .medium)

    // MARK: - Specialized Styles

    /// Scientific names, italicized text
    let italic = Font.system(.subheadline, design: .default, weight: .regular).italic()
    let scientificName = Font.system(.subheadline, design: .default, weight: .regular).italic()

    /// Monospaced for IDs and codes
    let monospace = Font.system(.caption2, design: .monospaced, weight: .regular)

    /// Button text
    let buttonLarge = Font.system(.body, design: .default, weight: .semibold)
    let buttonMedium = Font.system(.callout, design: .default, weight: .semibold)
    let buttonSmall = Font.system(.subheadline, design: .default, weight: .medium)
}

// MARK: - View Extensions for Typography

extension View {
    /// Apply a semantic text style with proper color
    func textStyle(_ style: TextStyle, color: Color? = nil) -> some View {
        self.modifier(TextStyleModifier(style: style, color: color))
    }
}

/// Text style categories
enum TextStyle {
    case displayLarge
    case displayMedium
    case displaySmall
    case headingLarge
    case headingMedium
    case headingSmall
    case bodyLarge
    case bodyMedium
    case bodySmall
    case bodyLargeEmphasized
    case bodyMediumEmphasized
    case captionLarge
    case captionMedium
    case captionSmall
    case captionLargeEmphasized
    case italic
    case scientificName
    case monospace
    case buttonLarge
    case buttonMedium
    case buttonSmall
}

private struct TextStyleModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let style: TextStyle
    let color: Color?

    func body(content: Content) -> some View {
        content
            .font(font(for: style))
            .foregroundColor(color ?? theme.colors.textPrimary)
    }

    private func font(for style: TextStyle) -> Font {
        let typography = theme.typography
        switch style {
        case .displayLarge: return typography.displayLarge
        case .displayMedium: return typography.displayMedium
        case .displaySmall: return typography.displaySmall
        case .headingLarge: return typography.headingLarge
        case .headingMedium: return typography.headingMedium
        case .headingSmall: return typography.headingSmall
        case .bodyLarge: return typography.bodyLarge
        case .bodyMedium: return typography.bodyMedium
        case .bodySmall: return typography.bodySmall
        case .bodyLargeEmphasized: return typography.bodyLargeEmphasized
        case .bodyMediumEmphasized: return typography.bodyMediumEmphasized
        case .captionLarge: return typography.captionLarge
        case .captionMedium: return typography.captionMedium
        case .captionSmall: return typography.captionSmall
        case .captionLargeEmphasized: return typography.captionLargeEmphasized
        case .italic: return typography.italic
        case .scientificName: return typography.scientificName
        case .monospace: return typography.monospace
        case .buttonLarge: return typography.buttonLarge
        case .buttonMedium: return typography.buttonMedium
        case .buttonSmall: return typography.buttonSmall
        }
    }
}
