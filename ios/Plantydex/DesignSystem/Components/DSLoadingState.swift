//
//  DSLoadingState.swift
//  Plantydex Design System
//
//  Token-driven loading state component.
//

import SwiftUI

/// A design system loading state component that uses tokens for all styling.
struct DSLoadingState: View {
    @Environment(\.theme) private var theme

    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(theme.colors.primary)

            if let message = message {
                Text(message)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.xl)
    }
}

// MARK: - Inline Loading

/// Inline loading indicator for use within other views
struct DSInlineLoading: View {
    @Environment(\.theme) private var theme

    let message: String

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ProgressView()
                .scaleEffect(0.8)

            Text(message)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
    }
}

// MARK: - Previews

#Preview("Loading State") {
    ThemeProvider {
        DSLoadingState(message: "Loading plants...")
    }
}

#Preview("Loading State - No Message") {
    ThemeProvider {
        DSLoadingState()
    }
}

#Preview("Inline Loading") {
    ThemeProvider {
        VStack(spacing: 16) {
            DSInlineLoading(message: "Identifying plant...")
            DSInlineLoading(message: "Uploading photo...")
        }
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        DSLoadingState(message: "Loading plants...")
    }
    .preferredColorScheme(.dark)
}
