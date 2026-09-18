//
//  PlantDetailView.swift
//  Plantydex
//
//  Created by Claude Code on 1/3/26.
//

import SwiftData
import SwiftUI

struct PlantDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Bindable var plant: Plant

    @State private var isEditing = false
    @State private var draftDisplayName = ""
    @State private var draftNotes = ""
    @State private var showToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                headerSection
                    .padding(.horizontal, theme.spacing.screenEdge)

                Divider()
                    .padding(.horizontal, theme.spacing.screenEdge)

                notesSection
                plantDetailsSection

                if !plant.referenceImages.isEmpty {
                    referenceImagesSection
                }
            }
            .padding(.bottom, theme.spacing.screenEdge)
        }
        .navigationTitle(plant.title)
        .navigationBarTitleDisplayMode(.large)
        .overlay(toastOverlay)
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            if let thumbnail = plant.thumbnail, let image = UIImage(data: thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(plant.title)
                    .font(theme.typography.displaySmall)
                    .foregroundColor(theme.colors.textPrimary)

                Text("\(plant.sightingCount) \(plant.sightingCount == 1 ? "sighting" : "sightings")")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)

                if let lastSeen = plant.lastSeenAt {
                    Text("Last seen: \(lastSeen.formatted(date: .abbreviated, time: .shortened))")
                        .font(theme.typography.captionLarge)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    Text("Notes")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    if !isEditing {
                        Button("Edit") { beginEditing() }
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.primary)
                    }
                }

                if isEditing {
                    editingView
                } else if let notes = plant.notes, !notes.isEmpty {
                    Text(notes)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No notes yet")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var editingView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.formFieldSpacing) {
            DSTextField(
                label: "Display Name",
                placeholder: "Enter display name",
                text: $draftDisplayName
            )

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text("Notes")
                    .font(theme.typography.captionLargeEmphasized)
                    .foregroundColor(theme.colors.textSecondary)

                TextEditor(text: $draftNotes)
                    .frame(minHeight: 100)
                    .padding(theme.spacing.xs)
                    .background(theme.colors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.input)
                            .stroke(theme.colors.borderSecondary, lineWidth: 1)
                    )
            }

            HStack(spacing: theme.spacing.sm) {
                DSButton("Cancel", style: .secondary) { isEditing = false }
                DSButton("Save", style: .primary) { save() }
            }
        }
    }

    @ViewBuilder
    private var plantDetailsSection: some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Plant Details")
                    .font(theme.typography.headingMedium)
                    .foregroundColor(theme.colors.textPrimary)

                if let commonName = plant.commonName {
                    detailField(label: "Common Name", value: commonName, isItalic: false)
                }
                if let scientific = plant.scientificName {
                    detailField(label: "Scientific Name", value: scientific, isItalic: true)
                }
                if let family = plant.family {
                    detailField(label: "Family", value: family, isItalic: true)
                }
                if let genus = plant.genus {
                    detailField(label: "Genus", value: genus, isItalic: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func detailField(label: String, value: String, isItalic: Bool) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
            Text(label)
                .font(theme.typography.captionLarge)
                .foregroundColor(theme.colors.textSecondary)

            Text(value)
                .font(isItalic ? theme.typography.scientificName : theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    @ViewBuilder
    private var referenceImagesSection: some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Reference Images")
                    .font(theme.typography.headingMedium)
                    .foregroundColor(theme.colors.textPrimary)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: theme.spacing.xs
                ) {
                    ForEach(Array(plant.referenceImages.prefix(6).enumerated()), id: \.offset) { _, image in
                        if let urlString = image.url, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 100)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
                                case .failure:
                                    theme.colors.surfaceSecondary
                                        .frame(height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
                                case .empty:
                                    ZStack {
                                        theme.colors.surfaceSecondary
                                        ProgressView()
                                    }
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        Group {
            if showToast {
                VStack {
                    Spacer()
                    Text("Changes saved!")
                        .font(theme.typography.bodyMedium)
                        .padding(theme.spacing.md)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.button))
                        .padding(.bottom, theme.spacing.xxxl)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showToast)
    }

    // MARK: - Editing

    private func beginEditing() {
        draftDisplayName = plant.displayName ?? ""
        draftNotes = plant.notes ?? ""
        isEditing = true
    }

    private func save() {
        plant.displayName = draftDisplayName.isEmpty ? nil : draftDisplayName
        plant.notes = draftNotes.isEmpty ? nil : draftNotes
        plant.notesUpdatedAt = Date()
        try? modelContext.save()

        isEditing = false
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            showToast = false
        }
    }
}
