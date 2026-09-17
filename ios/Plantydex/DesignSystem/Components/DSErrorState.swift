//
//  DSErrorState.swift
//  Plantydex Design System
//
//  Token-driven error state component.
//

import SwiftUI

/// A design system error state component that uses tokens for all styling.
struct DSErrorState: View {
    @Environment(\.theme) private var theme

    let title: String
    let message: String
    let retryAction: (() -> Void)?

    init(
        title: String = "Something Went Wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.colors.error)

            // Text content
            VStack(spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.headingLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Optional retry button
            if let retryAction = retryAction {
                DSButton("Try Again", icon: "arrow.clockwise", style: .secondary, action: retryAction)
                    .frame(maxWidth: 280)
            }
        }
        .padding(theme.spacing.xl)
    }
}

// MARK: - Inline Error

/// Inline error banner for use within other views
struct DSInlineError: View {
    @Environment(\.theme) private var theme

    let message: String
    let retryAction: (() -> Void)?

    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(theme.colors.error)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(message)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textPrimary)

                if let retryAction = retryAction {
                    Button("Try Again") {
                        retryAction()
                    }
                    .font(theme.typography.captionLargeEmphasized)
                    .foregroundColor(theme.colors.primary)
                }
            }

            Spacer()
        }
        .padding(theme.spacing.md)
        .background(theme.colors.errorSubdued)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
    }
}

// MARK: - Previews

#Preview("Error State with Retry") {
    ThemeProvider {
        DSErrorState(
            title: "Connection Failed",
            message: "Unable to load plant data. Please check your internet connection and try again.",
            retryAction: {
                print("Retry tapped")
            }
        )
    }
}

#Preview("Error State without Retry") {
    ThemeProvider {
        DSErrorState(
            title: "Not Found",
            message: "The plant you're looking for doesn't exist."
        )
    }
}

#Preview("Inline Error") {
    ThemeProvider {
        VStack(spacing: 16) {
            DSInlineError(
                message: "Failed to upload image. Please try again.",
                retryAction: { print("Retry") }
            )

            DSInlineError(
                message: "This field is required."
            )
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        DSErrorState(
            message: "Unable to identify plant from the provided image.",
            retryAction: {}
        )
    }
    .preferredColorScheme(.dark)
}
