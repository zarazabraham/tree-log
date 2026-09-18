//
//  Sighting.swift
//  Plantydex
//

import Foundation
import SwiftData

/// One photo the user took of a plant. Formerly the `sightings` table.
@Model
final class Sighting {
    var id: UUID = UUID()
    var createdAt: Date = Date()

    /// Downscaled JPEG. External storage keeps the SQLite file small and lets CloudKit
    /// sync it as a CKAsset instead of inlining it in the record.
    @Attribute(.externalStorage)
    var photo: Data?

    var latitude: Double?
    var longitude: Double?
    var confidence: Double?

    var plant: Plant?

    init(
        photo: Data?,
        latitude: Double? = nil,
        longitude: Double? = nil,
        confidence: Double? = nil,
        plant: Plant? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.photo = photo
        self.latitude = latitude
        self.longitude = longitude
        self.confidence = confidence
        self.plant = plant
    }
}
