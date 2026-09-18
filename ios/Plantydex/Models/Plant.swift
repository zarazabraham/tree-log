//
//  Plant.swift
//  Plantydex
//

import Foundation
import SwiftData

/// A species in the user's collection. One row per identified species; sightings hang off it.
///
/// CloudKit-compatible by construction: no unique constraints, optional relationships, and a
/// default on every non-optional property. `key` is deduplicated in code (IdentifyService
/// fetches before inserting), not by the schema.
@Model
final class Plant {
    /// Slugified scientific name from identify-tree — the stable identity of a species.
    var key: String = ""
    var commonName: String?
    var scientificName: String?
    var family: String?
    var genus: String?
    var commonNames: [String] = []
    var gbifId: String?
    var powoId: String?
    var iucnCategory: String?
    var referenceImages: [ReferenceImage] = []

    // User annotations. Formerly the `tree_entries` table.
    var displayName: String?
    var notes: String?
    var notesUpdatedAt: Date?

    // US regions where GBIF has occurrence records for this species. Formerly the
    // `plant_region_distribution` table; RegionService refreshes on a 30-day TTL.
    var regionIds: [String] = []
    var regionsFetchedAt: Date?

    // Denormalized from `sightings` so the log can sort and count without a view.
    // This is exactly what the old `plant_log` SQL view computed.
    var lastSeenAt: Date?
    var sightingCount: Int = 0

    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Sighting.plant)
    var sightings: [Sighting]?

    init(
        key: String,
        commonName: String? = nil,
        scientificName: String? = nil,
        family: String? = nil,
        genus: String? = nil,
        commonNames: [String] = [],
        gbifId: String? = nil,
        powoId: String? = nil,
        iucnCategory: String? = nil,
        referenceImages: [ReferenceImage] = []
    ) {
        self.key = key
        self.commonName = commonName
        self.scientificName = scientificName
        self.family = family
        self.genus = genus
        self.commonNames = commonNames
        self.gbifId = gbifId
        self.powoId = powoId
        self.iucnCategory = iucnCategory
        self.referenceImages = referenceImages
        self.createdAt = Date()
    }

    /// Name shown in lists: the user's override if set, else Pl@ntNet's common name.
    var title: String {
        if let displayName, !displayName.isEmpty { return displayName }
        return commonName ?? scientificName ?? "Unknown plant"
    }

    /// Most recent sighting's photo, used as the thumbnail.
    var thumbnail: Data? {
        sightings?.max(by: { $0.createdAt < $1.createdAt })?.photo
    }
}
