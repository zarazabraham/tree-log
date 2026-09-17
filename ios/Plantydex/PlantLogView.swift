//
//  PlantLogView.swift
//  Plantydex
//
//  Created by Zara Abraham on 1/2/26.
//
import SwiftUI

struct PlantLogView: View {
    @Environment(\.theme) private var theme
    @State private var rows: [PlantLogRow] = []
    @State private var loading = true
    @State private var error: String?
    @State private var showingAddPlant = false

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    DSLoadingState(message: "Loading plants...")
                } else if let error {
                    DSErrorState(
                        title: "Failed to Load Plants",
                        message: error,
                        retryAction: {
                            Task { await load() }
                        }
                    )
                } else if rows.isEmpty {
                    DSEmptyState(
                        icon: "leaf",
                        title: "No Plants Yet",
                        message: "Start your plant collection by identifying your first plant.",
                        actionTitle: "Add Plant"
                    ) {
                        showingAddPlant = true
                    }
                } else {
                    List(rows) { row in
                        NavigationLink(destination: PlantDetailView(plantKey: row.key)) {
                            DSListRow(
                                title: row.name ?? "Unknown plant",
                                subtitle: "\(row.sightings_count) \(row.sightings_count == 1 ? "sighting" : "sightings") • Last seen: \(formatDate(row.last_seen))",
                                imageURL: URL(string: row.thumbnail_url ?? "")
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(theme.typography.captionMedium)
                                    .foregroundColor(theme.colors.textTertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Plant Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlant = true
                    } label: {
                        Label("Add Plant", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                AddPlantView(isPresented: $showingAddPlant) {
                    // Refresh the log after adding a plant
                    Task {
                        await load()
                    }
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        error = nil
        do {
            print("DEBUG: Starting fetchPlantLog...")
            rows = try await SupabaseAPI.shared.fetchPlantLog()
            print("DEBUG: Successfully loaded \(rows.count) rows")
        } catch {
            print("DEBUG: Error loading plant log: \(error)")
            self.error = error.localizedDescription
            rows = []
        }
        loading = false
    }

    private func formatDate(_ iso: String?) -> String {
        guard let iso else { return "—" }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return iso
    }
}
