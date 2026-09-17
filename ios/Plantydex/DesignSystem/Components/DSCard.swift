//
//  DSCard.swift
//  Plantydex Design System
//
//  Token-driven card/surface component for containing content.
//

import SwiftUI

/// A design system card component that uses tokens for all styling.
/// Provides consistent surface styling for content containers.
struct DSCard<Content: View>: View {
    @Environment(\.theme) private var theme

    let content: Content
    let elevation: ElevationLevel
    let padding: SpacingValue

    init(
        elevation: ElevationLevel = .level2,
        padding: SpacingValue = .cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding.value)
            .background(theme.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
            .elevation(elevation)
    }
}

// MARK: - Previews

#Preview("Basic Card") {
    ThemeProvider {
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Title")
                    .font(.headline)
                Text("This is a basic card with some content inside.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

#Preview("Card Elevations") {
    ThemeProvider {
        ScrollView {
            VStack(spacing: 24) {
                DSCard(elevation: .none) {
                    Text("No Elevation")
                        .frame(maxWidth: .infinity)
                }

                DSCard(elevation: .level1) {
                    Text("Level 1")
                        .frame(maxWidth: .infinity)
                }

                DSCard(elevation: .level2) {
                    Text("Level 2 (Default)")
                        .frame(maxWidth: .infinity)
                }

                DSCard(elevation: .level3) {
                    Text("Level 3")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Card in Dark Mode")
                    .font(.headline)
                Text("Cards adapt to dark mode automatically.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
