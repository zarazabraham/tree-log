//
//  RegionDiscoveryView.swift
//  Plantydex
//

import SwiftUI

struct RegionDiscoveryView: View {
    let region: USRegion
    let plantsHereCount: Int
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme
    @State private var iconScale: CGFloat = 0.2
    @State private var iconOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var detailOpacity: CGFloat = 0
    @State private var buttonOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            // Background gradient using the region's colour
            LinearGradient(
                colors: [
                    region.color.opacity(0.95),
                    region.color.opacity(0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Large region icon
                Image(systemName: region.icon)
                    .font(.system(size: 96, weight: .regular))
                    .foregroundStyle(.white)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .padding(.bottom, theme.spacing.xl)

                // "Region Discovered!"
                Text("Region Discovered!")
                    .font(theme.typography.headingLarge)
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(titleOpacity)
                    .padding(.bottom, theme.spacing.xs)

                // Region name
                Text(region.name)
                    .font(theme.typography.displayMedium)
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .padding(.bottom, theme.spacing.sm)

                // State list
                Text(region.states)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.75))
                    .opacity(titleOpacity)
                    .padding(.bottom, theme.spacing.xxl)

                // Plants hint
                if plantsHereCount > 0 {
                    Text("\(plantsHereCount) of your plants grow in this region")
                        .font(theme.typography.bodyLarge)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(detailOpacity)
                        .padding(.horizontal, theme.spacing.screenEdge)
                        .padding(.bottom, theme.spacing.xxl)
                }

                Spacer()

                // CTA button
                Button(action: onDismiss) {
                    Text("Start Exploring")
                        .font(theme.typography.buttonLarge)
                        .foregroundStyle(region.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.md)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.button))
                }
                .opacity(buttonOpacity)
                .padding(.horizontal, theme.spacing.screenEdge)
                .padding(.bottom, theme.spacing.xxxl)
            }
        }
        .onAppear { runEntrance() }
    }

    private func runEntrance() {
        // Icon pops in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        // Title fades in after icon settles
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            titleOpacity = 1.0
        }
        // Detail + button stagger in last
        withAnimation(.easeOut(duration: 0.35).delay(0.6)) {
            detailOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.8)) {
            buttonOpacity = 1.0
        }
    }
}
