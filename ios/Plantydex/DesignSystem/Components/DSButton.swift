//
//  DSButton.swift
//  Plantydex Design System
//
//  Token-driven button component with multiple styles and states.
//

import SwiftUI

/// A design system button that uses tokens for all styling.
/// Supports primary, secondary, tertiary styles with loading and disabled states.
struct DSButton: View {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.buttonIconSpacing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                }

                Text(title)
                    .font(font)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, theme.spacing.buttonPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.button))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.button)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(effectiveOpacity)
    }

    // MARK: - Style Calculations

    private var backgroundColor: Color {
        guard isEnabled && !isLoading else {
            return theme.colors.surfaceSecondary
        }

        switch style {
        case .primary:
            return theme.colors.primary
        case .secondary:
            return theme.colors.surfacePrimary
        case .tertiary:
            return Color.clear
        case .destructive:
            return theme.colors.error
        }
    }

    private var textColor: Color {
        guard isEnabled && !isLoading else {
            return theme.colors.textTertiary
        }

        switch style {
        case .primary:
            return theme.colors.textOnPrimary
        case .secondary:
            return theme.colors.primary
        case .tertiary:
            return theme.colors.primary
        case .destructive:
            return theme.colors.textOnPrimary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .destructive:
            return Color.clear
        case .secondary:
            return theme.colors.borderPrimary
        case .tertiary:
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .primary, .tertiary, .destructive:
            return 0
        case .secondary:
            return 1
        }
    }

    private var font: Font {
        switch size {
        case .small:
            return theme.typography.buttonSmall
        case .medium:
            return theme.typography.buttonMedium
        case .large:
            return theme.typography.buttonLarge
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small:
            return theme.spacing.xs
        case .medium:
            return theme.spacing.sm
        case .large:
            return theme.spacing.md
        }
    }

    private var effectiveOpacity: Double {
        if !isEnabled || isLoading {
            return 0.5
        }
        return 1.0
    }
}

// MARK: - Button Style Enum

extension DSButton {
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
    }

    enum ButtonSize {
        case small
        case medium
        case large
    }
}

// MARK: - Previews

#Preview("Button Styles - Light Mode") {
    ThemeProvider {
        VStack(spacing: 16) {
            DSButton("Primary Button", icon: "leaf.fill", style: .primary) {}
            DSButton("Secondary Button", icon: "photo.on.rectangle", style: .secondary) {}
            DSButton("Tertiary Button", icon: "arrow.clockwise", style: .tertiary) {}
            DSButton("Destructive Button", icon: "trash", style: .destructive) {}
        }
        .padding()
    }
}

#Preview("Button States") {
    ThemeProvider {
        VStack(spacing: 16) {
            DSButton("Enabled Button", style: .primary) {}

            DSButton("Loading Button", style: .primary, isLoading: true) {}

            DSButton("Disabled Button", style: .primary) {}
                .disabled(true)

            DSButton("Loading Secondary", style: .secondary, isLoading: true) {}
        }
        .padding()
    }
}

#Preview("Button Sizes") {
    ThemeProvider {
        VStack(spacing: 16) {
            DSButton("Small Button", icon: "leaf.fill", style: .primary, size: .small) {}
            DSButton("Medium Button", icon: "leaf.fill", style: .primary, size: .medium) {}
            DSButton("Large Button", icon: "leaf.fill", style: .primary, size: .large) {}
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        VStack(spacing: 16) {
            DSButton("Primary Button", icon: "leaf.fill", style: .primary) {}
            DSButton("Secondary Button", icon: "photo.on.rectangle", style: .secondary) {}
            DSButton("Tertiary Button", icon: "arrow.clockwise", style: .tertiary) {}
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
