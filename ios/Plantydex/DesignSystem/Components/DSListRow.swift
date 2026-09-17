//
//  DSListRow.swift
//  Plantydex Design System
//
//  Token-driven list row component for consistent list items.
//

import SwiftUI

/// A design system list row component that uses tokens for all styling.
struct DSListRow<Accessory: View>: View {
    @Environment(\.theme) private var theme

    let title: String
    let subtitle: String?
    let icon: String?
    let imageURL: URL?
    let accessory: Accessory?

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        imageURL: URL? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.imageURL = imageURL
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Leading image or icon
            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        Color.gray.opacity(0.2)
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(theme.colors.primary)
                    .frame(width: 40, height: 40)
            }

            // Text content
            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(title)
                    .font(theme.typography.bodyMediumEmphasized)
                    .foregroundColor(theme.colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.typography.captionLarge)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            Spacer(minLength: theme.spacing.xs)

            // Trailing accessory
            if accessory != nil {
                accessory
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - Convenience Initializer for Simple Rows

extension DSListRow where Accessory == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        imageURL: URL? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.imageURL = imageURL
        self.accessory = nil
    }
}

// MARK: - Previews

#Preview("List Rows with Icons") {
    ThemeProvider {
        List {
            DSListRow(
                title: "Monstera Deliciosa",
                subtitle: "Swiss Cheese Plant",
                icon: "leaf.fill"
            )

            DSListRow(
                title: "Pothos",
                subtitle: "Devil's Ivy",
                icon: "leaf.fill"
            )

            DSListRow(
                title: "Snake Plant",
                subtitle: "Sansevieria",
                icon: "leaf.fill"
            )
        }
    }
}

#Preview("List Rows with Images") {
    ThemeProvider {
        List {
            DSListRow(
                title: "Monstera Deliciosa",
                subtitle: "Added 2 days ago",
                imageURL: URL(string: "https://via.placeholder.com/150")
            ) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }

            DSListRow(
                title: "Pothos",
                subtitle: "Added 1 week ago",
                imageURL: URL(string: "https://via.placeholder.com/150")
            ) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("List Row with Badge") {
    ThemeProvider {
        List {
            DSListRow(
                title: "Rhaphidophora Tetrasperma",
                subtitle: "Mini Monstera",
                icon: "leaf.fill"
            ) {
                Text("New")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        List {
            DSListRow(
                title: "Monstera Deliciosa",
                subtitle: "Swiss Cheese Plant",
                icon: "leaf.fill"
            )

            DSListRow(
                title: "Pothos",
                subtitle: "Devil's Ivy",
                icon: "leaf.fill"
            )
        }
    }
    .preferredColorScheme(.dark)
}
