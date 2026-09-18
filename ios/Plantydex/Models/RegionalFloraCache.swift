//
//  RegionalFloraCache.swift
//  Plantydex
//

import Foundation
import SwiftData

/// Species count for a Pl@ntNet regional project. Mirrors the server-side
/// `regional_flora_cache` table so the Progress tab renders instantly on launch.
/// RegionService treats rows older than 7 days as stale.
@Model
final class RegionalFloraCache {
    var projectId: String = ""
    var projectName: String = ""
    var speciesCount: Int = 0
    var fetchedAt: Date = Date()

    init(projectId: String, projectName: String, speciesCount: Int, fetchedAt: Date = Date()) {
        self.projectId = projectId
        self.projectName = projectName
        self.speciesCount = speciesCount
        self.fetchedAt = fetchedAt
    }
}
