//
//  RadiiTokens.swift
//  Plantydex Design System
//
//  Border radius tokens for consistent rounded corners.
//

import SwiftUI

/// Border radius tokens for rounded corners.
struct RadiiTokens {

    // MARK: - Radius Scale

    /// No radius - sharp corners
    let none: CGFloat = 0

    /// 4pt - Small radius for subtle rounding
    let sm: CGFloat = 4

    /// 8pt - Medium radius (default for most elements)
    let md: CGFloat = 8

    /// 10pt - Medium-large radius
    let lg: CGFloat = 10

    /// 12pt - Large radius (cards, containers)
    let xl: CGFloat = 12

    /// 16pt - Extra large radius
    let xxl: CGFloat = 16

    /// 20pt - Huge radius (prominent elements)
    let huge: CGFloat = 20

    /// Fully rounded (pill shape)
    let full: CGFloat = 9999

    // MARK: - Semantic Radii

    /// Buttons
    let button: CGFloat = 10

    /// Cards and containers
    let card: CGFloat = 12

    /// Input fields
    let input: CGFloat = 10

    /// Images and thumbnails
    let image: CGFloat = 8

    /// Modal sheets and dialogs
    let modal: CGFloat = 16

    /// Small chips and badges
    let chip: CGFloat = 8
}

// MARK: - View Extensions for Corner Radius

extension View {
    /// Apply corner radius using radius tokens
    func cornerRadius(_ radius: RadiusValue) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius.value))
    }

    /// Apply corner radius with specific corners using radius tokens
    func cornerRadius(_ radius: RadiusValue, corners: UIRectCorner) -> some View {
        self.clipShape(
            RoundedCorner(radius: radius.value, corners: corners)
        )
    }
}

/// Semantic radius values that can be used throughout the app
enum RadiusValue {
    case none
    case sm
    case md
    case lg
    case xl
    case xxl
    case huge
    case full
    case button
    case card
    case input
    case image
    case modal
    case chip
    case custom(CGFloat)

    var value: CGFloat {
        let tokens = RadiiTokens()
        switch self {
        case .none: return tokens.none
        case .sm: return tokens.sm
        case .md: return tokens.md
        case .lg: return tokens.lg
        case .xl: return tokens.xl
        case .xxl: return tokens.xxl
        case .huge: return tokens.huge
        case .full: return tokens.full
        case .button: return tokens.button
        case .card: return tokens.card
        case .input: return tokens.input
        case .image: return tokens.image
        case .modal: return tokens.modal
        case .chip: return tokens.chip
        case .custom(let value): return value
        }
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
