//
//  PlantLogView.swift
//  Plantydex
//
//  Created by Zara Abraham on 1/2/26.
//

import SwiftData
import SwiftUI

struct PlantLogView: View {
    @Environment(\.theme) private var theme

    @Query(sort: \Plant.lastSeenAt, order: .reverse)
    private var allPlants: [Plant]

    @State private var showingAddPlant = false

    /// CloudKit cannot enforce uniqueness, so two offline devices can each create a Plant
    /// with the same key. Collapse them on read, keeping the most recently seen.
    private var plants: [Plant] {
        var seen = Set<String>()
        return allPlants.filter { seen.insert($0.key).inserted }
    }

    var body: some View {
        NavigationStack {
            Group {
                if plants.isEmpty {
                    DSEmptyState(
                        icon: "leaf",
                        title: "No Plants Yet",
                        message: "Start your plant collection by identifying your first plant.",
                        actionTitle: "Add Plant"
                    ) {
                        showingAddPlant = true
                    }
                } else {
                    List(plants) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            DSListRow(
                                title: plant.title,
                                subtitle: subtitle(for: plant),
                                imageData: plant.thumbnail
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
                AddPlantView(isPresented: $showingAddPlant) {}
            }
        }
    }

    private func subtitle(for plant: Plant) -> String {
        let count = plant.sightingCount
        let noun = count == 1 ? "sighting" : "sightings"
        return "\(count) \(noun) • Last seen: \(formatDate(plant.lastSeenAt))"
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
