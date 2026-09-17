//
//  Theme.swift
//  Plantydex Design System
//
//  Central theme object that provides all design tokens via Environment.
//

import SwiftUI

/// The main theme object that provides access to all design tokens.
/// Inject this into the environment to make tokens available throughout the app.
struct Theme {
    let colors: ColorTokens
    let typography: TypographyTokens
    let spacing: SpacingTokens
    let radii: RadiiTokens
    let elevation: ElevationTokens
    let motion: MotionTokens

    /// Default theme with all tokens
    static let `default` = Theme(
        colors: ColorTokens(),
        typography: TypographyTokens(),
        spacing: SpacingTokens(),
        radii: RadiiTokens(),
        elevation: ElevationTokens(),
        motion: MotionTokens()
    )
}

// MARK: - Environment Key

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .default
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Apply theme to the view hierarchy
    func theme(_ theme: Theme) -> some View {
        self.environment(\.theme, theme)
    }
}

// MARK: - Theme Provider

/// A view that provides theme to its children
struct ThemeProvider<Content: View>: View {
    let theme: Theme
    let content: Content

    init(theme: Theme = .default, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.theme, theme)
    }
}
