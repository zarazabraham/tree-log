//
//  PlantDetailView.swift
//  Plantydex
//
//  Created by Claude Code on 1/3/26.
//

import SwiftUI

struct PlantDetailView: View {
    @Environment(\.theme) private var theme
    let plantKey: String

    @State private var loading = true
    @State private var error: String?

    // Data models
    @State private var logRow: PlantLogRow?
    @State private var plant: PlantData?
    @State private var displayName = ""
    @State private var notes = ""

    // Edit state
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showToast = false
    @State private var toastMessage = ""

    // Original values for cancel
    @State private var originalDisplayName = ""
    @State private var originalNotes = ""

    var body: some View {
        ScrollView {
            if loading {
                DSLoadingState(message: "Loading plant details...")
            } else if let error {
                DSErrorState(
                    title: "Failed to Load Details",
                    message: error,
                    retryAction: {
                        Task { await loadPlantDetails() }
                    }
                )
            } else {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header with thumbnail and summary
                    if let logRow {
                        headerSection(logRow: logRow)
                            .padding(.horizontal, theme.spacing.screenEdge)
                    }

                    Divider()
                        .padding(.horizontal, theme.spacing.screenEdge)

                    // Notes section
                    notesSection()

                    // Plant details section
                    plantDetailsSection()

                    // Reference images
                    if let plant, let images = plant.reference_images, !images.isEmpty {
                        referenceImagesSection(images: images)
                    }
                }
                .padding(.bottom, theme.spacing.screenEdge)
            }
        }
        .navigationTitle(logRow?.name ?? "Plant Details")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadPlantDetails()
        }
        .overlay(toastOverlay)
    }

    // MARK: - Sections

    @ViewBuilder
    private func headerSection(logRow: PlantLogRow) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            // Thumbnail
            if let thumbnailUrl = logRow.thumbnail_url {
                AsyncImage(url: URL(string: thumbnailUrl)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            theme.colors.surfaceSecondary
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            theme.colors.surfaceSecondary
                            Image(systemName: "photo")
                                .foregroundColor(theme.colors.textTertiary)
                        }
                    @unknown default:
                        theme.colors.surfaceSecondary
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(displayName.isEmpty ? (logRow.name ?? "Unknown") : displayName)
                    .font(theme.typography.displaySmall)
                    .foregroundColor(theme.colors.textPrimary)

                Text("\(logRow.sightings_count) \(logRow.sightings_count == 1 ? "sighting" : "sightings")")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)

                if let lastSeen = logRow.last_seen {
                    Text("Last seen: \(formatDate(lastSeen))")
                        .font(theme.typography.captionLarge)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func notesSection() -> some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    Text("Notes")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    if !isEditing {
                        Button("Edit") {
                            originalDisplayName = displayName
                            originalNotes = notes
                            isEditing = true
                        }
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.primary)
                    }
                }

                if isEditing {
                    editingView()
                } else {
                    if notes.isEmpty {
                        Text("No notes yet")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .italic()
                    } else {
                        Text(notes)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func editingView() -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.formFieldSpacing) {
            DSTextField(
                label: "Display Name",
                placeholder: "Enter display name",
                text: $displayName
            )

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text("Notes")
                    .font(theme.typography.captionLargeEmphasized)
                    .foregroundColor(theme.colors.textSecondary)

                TextEditor(text: $notes)
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
                DSButton("Cancel", style: .secondary) {
                    displayName = originalDisplayName
                    notes = originalNotes
                    isEditing = false
                }

                DSButton("Save", style: .primary, isLoading: isSaving) {
                    Task {
                        await saveChanges()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func plantDetailsSection() -> some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Plant Details")
                    .font(theme.typography.headingMedium)
                    .foregroundColor(theme.colors.textPrimary)

                if let plant {
                    // Common name
                    if let commonName = plant.common_name {
                        detailField(label: "Common Name", value: commonName, isItalic: false)
                    }

                    // Scientific name
                    if let scientific = plant.scientific_name {
                        detailField(label: "Scientific Name", value: scientific, isItalic: true)
                    }

                    // Family
                    if let family = plant.family {
                        detailField(label: "Family", value: family, isItalic: true)
                    }

                    // Genus
                    if let genus = plant.genus {
                        detailField(label: "Genus", value: genus, isItalic: true)
                    }
                } else {
                    Text("No plant details found for this key yet.")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
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
    private func referenceImagesSection(images: [[String: Any]]) -> some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Reference Images")
                    .font(theme.typography.headingMedium)
                    .foregroundColor(theme.colors.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.xs) {
                    ForEach(Array(images.prefix(6).enumerated()), id: \.offset) { _, image in
                        if let urlString = getRefImageUrl(image),
                           let url = URL(string: urlString) {
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
                    Text(toastMessage)
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

    // MARK: - Data Loading

    private func loadPlantDetails() async {
        loading = true
        error = nil

        do {
            // 1. Load plant log row
            let logData = try await SupabaseAPI.shared.fetchPlantLogRow(key: plantKey)
            logRow = logData

            // 2. Load or create tree entry
            let entry = try await SupabaseAPI.shared.fetchOrCreateTreeEntry(key: plantKey)
            displayName = entry.display_name ?? ""
            notes = entry.notes ?? ""
            originalDisplayName = displayName
            originalNotes = notes

            // 3. Load plant data
            let plantData = try await SupabaseAPI.shared.fetchPlant(key: plantKey)
            plant = plantData

            // Debug reference images
            if let plant = plantData {
                print("DEBUG: Plant data loaded for key: \(plantKey)")
                print("DEBUG: Reference images count: \(plant.reference_images?.count ?? 0)")
                if let images = plant.reference_images {
                    for (i, img) in images.enumerated() {
                        print("DEBUG: Image \(i): \(img)")
                        if let url = getRefImageUrl(img) {
                            print("DEBUG: Extracted URL \(i): \(url)")
                        }
                    }
                }
            }

            loading = false
        } catch {
            print("DEBUG: Error loading plant details: \(error)")
            self.error = error.localizedDescription
            loading = false
        }
    }

    private func saveChanges() async {
        isSaving = true

        do {
            try await SupabaseAPI.shared.updateTreeEntry(
                key: plantKey,
                displayName: displayName.isEmpty ? nil : displayName,
                notes: notes.isEmpty ? nil : notes
            )

            originalDisplayName = displayName
            originalNotes = notes
            isEditing = false

            toastMessage = "Changes saved!"
            showToast = true

            Task {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                showToast = false
            }
        } catch {
            self.error = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Helpers

    private func formatDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return iso
    }

    private func getRefImageUrl(_ img: [String: Any]) -> String? {
        if let url = img["url"] as? String {
            return url
        }
        if let urls = img["urls"] as? [String: String] {
            return urls["m"] ?? urls["s"] ?? urls["o"]
        }
        if let url = img["url"] as? [String: String] {
            return url["m"] ?? url["s"] ?? url["o"]
        }
        return nil
    }
}

// MARK: - Data Models

// Plant data model
struct PlantData: Decodable {
    let key: String
    let common_name: String?
    let scientific_name: String?
    let family: String?
    let genus: String?
    let reference_images: [[String: Any]]?
    let plant_details: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case key, common_name, scientific_name, family, genus, reference_images, plant_details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        common_name = try container.decodeIfPresent(String.self, forKey: .common_name)
        scientific_name = try container.decodeIfPresent(String.self, forKey: .scientific_name)
        family = try container.decodeIfPresent(String.self, forKey: .family)
        genus = try container.decodeIfPresent(String.self, forKey: .genus)

        // Decode reference_images as generic JSON
        if let jsonValue = try? container.decodeIfPresent(JSONValue.self, forKey: .reference_images),
           case .array(let arr) = jsonValue {
            reference_images = arr.compactMap { value -> [String: Any]? in
                if case .object(let dict) = value {
                    return dict
                }
                return nil
            }
        } else {
            reference_images = nil
        }

        // Decode plant_details as generic JSON
        if let jsonValue = try? container.decodeIfPresent(JSONValue.self, forKey: .plant_details),
           case .object(let dict) = jsonValue {
            plant_details = dict
        } else {
            plant_details = nil
        }
    }
}

// Helper enum to decode arbitrary JSON
private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: Any])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: JSONValue].self) {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                result[key] = value.toAny()
            }
            self = .object(result)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode JSON value")
        }
    }

    func toAny() -> Any {
        switch self {
        case .string(let str): return str
        case .number(let num): return num
        case .bool(let bool): return bool
        case .object(let dict): return dict
        case .array(let arr): return arr.map { $0.toAny() }
        case .null: return NSNull()
        }
    }
}

// Tree entry model
struct TreeEntry: Decodable {
    let key: String
    let display_name: String?
    let notes: String?
    let updated_at: String?
    let created_at: String?
}

#Preview {
    NavigationStack {
        PlantDetailView(plantKey: "test-plant")
    }
}
