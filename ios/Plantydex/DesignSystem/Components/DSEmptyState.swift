//
//  DSEmptyState.swift
//  Plantydex Design System
//
//  Token-driven empty state component.
//

import SwiftUI

/// A design system empty state component that uses tokens for all styling.
struct DSEmptyState: View {
    @Environment(\.theme) private var theme

    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(theme.colors.textTertiary)

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

            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                DSButton(actionTitle, icon: "plus.circle.fill", style: .primary, action: action)
                    .frame(maxWidth: 280)
            }
        }
        .padding(theme.spacing.xl)
    }
}

// MARK: - Previews

#Preview("Empty State with Action") {
    ThemeProvider {
        DSEmptyState(
            icon: "leaf",
            title: "No Plants Yet",
            message: "Start your plant collection by identifying your first plant.",
            actionTitle: "Add Plant"
        ) {
            print("Add plant tapped")
        }
    }
}

#Preview("Empty State without Action") {
    ThemeProvider {
        DSEmptyState(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "We couldn't find any plants matching your search criteria."
        )
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        DSEmptyState(
            icon: "photo",
            title: "No Photos",
            message: "Upload a photo to identify plants.",
            actionTitle: "Upload Photo"
        ) {}
    }
    .preferredColorScheme(.dark)
}
