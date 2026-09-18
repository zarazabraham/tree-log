//
//  IdentifyFlowView.swift
//  Plantydex
//
//  The single identify flow: pick a photo, send it for identification, show the result.
//  Used by the Upload tab and by the "Add Plant" sheet on the Log tab, which differ only
//  in what their finish button does.
//

import CoreLocation
import SwiftData
import SwiftUI

struct IdentifyFlowView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    let finishTitle: String
    let finishIcon: String
    let onFinish: () -> Void

    @StateObject private var locationManager = LocationManager()

    @State private var selectedImageData: Data?
    @State private var isIdentifying = false
    @State private var error: String?
    @State private var identified: Plant?

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.sectionSpacing) {
                if selectedImageData == nil {
                    DSImagePicker(selectedImageData: $selectedImageData)
                        .padding(.horizontal, theme.spacing.screenEdge)
                } else if let imageData = selectedImageData,
                          let uiImage = UIImage(data: imageData) {
                    imagePreviewSection(image: uiImage)
                }

                if let error {
                    DSInlineError(message: error) {
                        self.error = nil
                        reset()
                    }
                    .padding(.horizontal, theme.spacing.screenEdge)
                }

                if let identified {
                    resultSection(plant: identified)
                }
            }
        }
        .task {
            // Coordinates are optional metadata on the sighting; the flow works without them.
            locationManager.requestLocation()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func imagePreviewSection(image: UIImage) -> some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    Text("Selected Photo")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    if identified == nil && !isIdentifying {
                        Button("Change") {
                            reset()
                        }
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.primary)
                    }
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
                    .elevation(.level2)

                if identified == nil && !isIdentifying {
                    DSButton(
                        "Identify Plant",
                        icon: "leaf.fill",
                        style: .primary,
                        action: identify
                    )
                }

                if isIdentifying {
                    DSInlineLoading(message: "Identifying plant...")
                }
            }
        }
        .padding(.horizontal, theme.spacing.screenEdge)
    }

    @ViewBuilder
    private func resultSection(plant: Plant) -> some View {
        let confidence = plant.sightings?
            .max(by: { $0.createdAt < $1.createdAt })?
            .confidence

        DSCard(elevation: .level2, padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.success)

                    Text("Plant Identified!")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.success)

                    Spacer()
                }

                Divider()

                VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                    Text(plant.title)
                        .font(theme.typography.displaySmall)
                        .foregroundColor(theme.colors.textPrimary)

                    if let scientific = plant.scientificName {
                        Text(scientific)
                            .font(theme.typography.scientificName)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                if let confidence {
                    HStack {
                        Text("Confidence:")
                            .font(theme.typography.bodyMediumEmphasized)
                            .foregroundColor(theme.colors.textPrimary)
                        Text("\(Int(confidence * 100))%")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                if plant.family != nil || plant.genus != nil {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        if let family = plant.family {
                            taxonomyRow(label: "Family:", value: family)
                        }
                        if let genus = plant.genus {
                            taxonomyRow(label: "Genus:", value: genus)
                        }
                    }
                }

                if !plant.referenceImages.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Reference Images")
                            .font(theme.typography.headingSmall)
                            .foregroundColor(theme.colors.textPrimary)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: theme.spacing.xs
                        ) {
                            ForEach(Array(plant.referenceImages.prefix(6).enumerated()), id: \.offset) { _, image in
                                if let urlString = image.url, let url = URL(string: urlString) {
                                    referenceThumbnail(url: url)
                                }
                            }
                        }
                    }
                }

                Divider()

                HStack(spacing: theme.spacing.sm) {
                    DSButton(finishTitle, icon: finishIcon, style: .primary) {
                        onFinish()
                    }

                    DSButton("Identify Another", icon: "arrow.clockwise", style: .secondary) {
                        reset()
                    }
                }
            }
        }
        .padding(.horizontal, theme.spacing.screenEdge)
    }

    @ViewBuilder
    private func taxonomyRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(theme.typography.bodyMediumEmphasized)
                .foregroundColor(theme.colors.textPrimary)
            Text(value)
                .font(theme.typography.scientificName)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    @ViewBuilder
    private func referenceThumbnail(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img):
                img
                    .resizable()
                    .scaledToFill()
                    .frame(height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
            case .failure:
                theme.colors.surfaceSecondary
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
            case .empty:
                ZStack {
                    theme.colors.surfaceSecondary
                    ProgressView()
                }
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - Actions

    private func reset() {
        selectedImageData = nil
        identified = nil
        error = nil
    }

    private func identify() {
        guard let imageData = selectedImageData else { return }

        isIdentifying = true
        error = nil
        identified = nil

        Task {
            do {
                identified = try await IdentifyService.identify(
                    imageData: imageData,
                    location: locationManager.location,
                    context: modelContext
                )
            } catch {
                self.error = error.localizedDescription
            }
            isIdentifying = false
        }
    }
}
