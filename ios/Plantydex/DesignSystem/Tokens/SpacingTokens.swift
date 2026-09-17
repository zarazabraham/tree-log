//
//  SpacingTokens.swift
//  Plantydex Design System
//
//  8-point grid system for consistent spacing.
//

import SwiftUI

/// Spacing tokens based on an 8-point grid system.
/// All spacing values are multiples of 4 or 8 for visual consistency.
struct SpacingTokens {

    // MARK: - Base Unit
    /// Base spacing unit (4pt)
    let baseUnit: CGFloat = 4

    // MARK: - Spacing Scale

    /// 2pt - Minimal spacing for very tight layouts
    let xxxs: CGFloat = 2

    /// 4pt - Extra extra small spacing
    let xxs: CGFloat = 4

    /// 8pt - Extra small spacing (compact padding)
    let xs: CGFloat = 8

    /// 12pt - Small spacing
    let sm: CGFloat = 12

    /// 16pt - Medium spacing (default padding)
    let md: CGFloat = 16

    /// 20pt - Medium-large spacing
    let lg: CGFloat = 20

    /// 24pt - Large spacing (section separation)
    let xl: CGFloat = 24

    /// 32pt - Extra large spacing
    let xxl: CGFloat = 32

    /// 40pt - Extra extra large spacing
    let xxxl: CGFloat = 40

    /// 48pt - Huge spacing (major sections)
    let huge: CGFloat = 48

    // MARK: - Semantic Spacing

    /// Padding inside cards and containers
    let cardPadding: CGFloat = 16

    /// Spacing between list items
    let listItemSpacing: CGFloat = 12

    /// Spacing between sections
    let sectionSpacing: CGFloat = 24

    /// Screen edge padding
    let screenEdge: CGFloat = 16

    /// Spacing between form fields
    let formFieldSpacing: CGFloat = 16

    /// Spacing inside buttons
    let buttonPadding: CGFloat = 16

    /// Spacing between button icon and text
    let buttonIconSpacing: CGFloat = 8
}

// MARK: - View Extensions for Spacing

extension View {
    /// Apply horizontal padding using spacing tokens
    func hPadding(_ spacing: SpacingValue) -> some View {
        self.padding(.horizontal, spacing.value)
    }

    /// Apply vertical padding using spacing tokens
    func vPadding(_ spacing: SpacingValue) -> some View {
        self.padding(.vertical, spacing.value)
    }

    /// Apply all-around padding using spacing tokens
    func allPadding(_ spacing: SpacingValue) -> some View {
        self.padding(.all, spacing.value)
    }
}

/// Semantic spacing values that can be used throughout the app
enum SpacingValue {
    case xxxs
    case xxs
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl
    case xxxl
    case huge
    case cardPadding
    case listItemSpacing
    case sectionSpacing
    case screenEdge
    case formFieldSpacing
    case buttonPadding
    case buttonIconSpacing
    case custom(CGFloat)

    var value: CGFloat {
        let tokens = SpacingTokens()
        switch self {
        case .xxxs: return tokens.xxxs
        case .xxs: return tokens.xxs
        case .xs: return tokens.xs
        case .sm: return tokens.sm
        case .md: return tokens.md
        case .lg: return tokens.lg
        case .xl: return tokens.xl
        case .xxl: return tokens.xxl
        case .xxxl: return tokens.xxxl
        case .huge: return tokens.huge
        case .cardPadding: return tokens.cardPadding
        case .listItemSpacing: return tokens.listItemSpacing
        case .sectionSpacing: return tokens.sectionSpacing
        case .screenEdge: return tokens.screenEdge
        case .formFieldSpacing: return tokens.formFieldSpacing
        case .buttonPadding: return tokens.buttonPadding
        case .buttonIconSpacing: return tokens.buttonIconSpacing
        case .custom(let value): return value
        }
    }
}
