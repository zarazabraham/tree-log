//
//  DSTextField.swift
//  Plantydex Design System
//
//  Token-driven text field component.
//

import SwiftUI

/// A design system text field that uses tokens for all styling.
struct DSTextField: View {
    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool

    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let errorMessage: String?

    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        icon: String? = nil,
        errorMessage: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.errorMessage = errorMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            // Label
            Text(label)
                .font(theme.typography.captionLargeEmphasized)
                .foregroundColor(theme.colors.textSecondary)

            // Text field with icon
            HStack(spacing: theme.spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(theme.colors.textSecondary)
                }

                TextField(placeholder, text: $text)
                    .font(theme.typography.bodyMedium)
                    .focused($isFocused)
            }
            .padding(theme.spacing.sm)
            .background(theme.colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.input))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.input)
                    .stroke(borderColor, lineWidth: 1)
            )

            // Error message
            if let errorMessage = errorMessage {
                HStack(spacing: theme.spacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                        .font(theme.typography.captionMedium)
                }
                .foregroundColor(theme.colors.error)
            }
        }
    }

    private var borderColor: Color {
        if let _ = errorMessage {
            return theme.colors.error
        }
        return isFocused ? theme.colors.primary : theme.colors.borderSecondary
    }
}

// MARK: - Previews

#Preview("Text Fields") {
    ThemeProvider {
        VStack(spacing: 24) {
            DSTextField(
                label: "Plant Name",
                placeholder: "Enter plant name",
                text: .constant(""),
                icon: "leaf.fill"
            )

            DSTextField(
                label: "Location",
                placeholder: "Where did you find it?",
                text: .constant("Backyard"),
                icon: "location.fill"
            )

            DSTextField(
                label: "Notes",
                placeholder: "Add notes",
                text: .constant(""),
                errorMessage: "This field is required"
            )
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        VStack(spacing: 24) {
            DSTextField(
                label: "Plant Name",
                placeholder: "Enter plant name",
                text: .constant(""),
                icon: "leaf.fill"
            )

            DSTextField(
                label: "Notes",
                placeholder: "Add notes",
                text: .constant("Beautiful plant"),
                icon: "note.text"
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
