//
//  RegionService.swift
//  Plantydex
//

import CoreLocation
import Foundation
import SwiftData

@MainActor
enum RegionService {
    /// Matches the server-side cache TTL in get-regional-flora.
    private static let floraTTL: TimeInterval = 7 * 24 * 60 * 60
    /// GBIF distributions change slowly; a month is plenty.
    private static let distributionTTL: TimeInterval = 30 * 24 * 60 * 60

    // MARK: - Regional flora

    /// Species count for the user's region. Served from the on-device cache when fresh,
    /// otherwise from the edge function (which holds its own shared cache and the
    /// Pl@ntNet key). The local copy means the Progress tab renders instantly on launch.
    static func regionalFlora(
        lat: Double,
        lon: Double,
        context: ModelContext
    ) async throws -> RegionalFloraCache {
        let cached = try? context.fetch(FetchDescriptor<RegionalFloraCache>())

        if let fresh = cached?.first(where: { Date().timeIntervalSince($0.fetchedAt) < floraTTL }) {
            return fresh
        }

        let result = try await fetchRegionalFlora(lat: lat, lon: lon)

        if let existing = cached?.first(where: { $0.projectId == result.projectId }) {
            existing.projectName = result.projectName
            existing.speciesCount = result.speciesCount
            existing.fetchedAt = Date()
            try? context.save()
            return existing
        }

        let record = RegionalFloraCache(
            projectId: result.projectId,
            projectName: result.projectName,
            speciesCount: result.speciesCount
        )
        context.insert(record)
        try? context.save()
        return record
    }

    private struct RegionalFloraResponse: Decodable {
        let projectId: String
        let projectName: String
        let speciesCount: Int
    }

    private static func fetchRegionalFlora(lat: Double, lon: Double) async throws -> RegionalFloraResponse {
        let url = SupabaseConfig.url.appendingPathComponent("functions/v1/get-regional-flora")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["lat": lat, "lon": lon])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "RegionService", code: status, userInfo: [
                NSLocalizedDescriptionKey: "Could not load regional flora (\(status)): \(body)"
            ])
        }

        return try JSONDecoder().decode(RegionalFloraResponse.self, from: data)
    }

    // MARK: - Plant distributions

    /// Fills in `regionIds` for any plant whose distribution is missing or stale.
    /// GBIF needs no API key, so this runs straight from the device.
    static func refreshDistributions(for plants: [Plant], context: ModelContext) async {
        let now = Date()
        let stale = plants.filter { plant in
            guard plant.scientificName != nil else { return false }
            guard let fetched = plant.regionsFetchedAt else { return true }
            return now.timeIntervalSince(fetched) >= distributionTTL
        }

        guard !stale.isEmpty else { return }

        for plant in stale {
            guard let scientificName = plant.scientificName else { continue }
            let states = await statesFromGBIF(scientificName: scientificName)
            plant.regionIds = USRegion.regionIds(forStateNames: states)
            plant.regionsFetchedAt = Date()
        }

        try? context.save()
    }

    /// Asks GBIF which US states have occurrence records for a species.
    /// Returns an empty list on any failure — a missing distribution just leaves
    /// regions locked rather than failing the whole screen.
    private static func statesFromGBIF(scientificName: String) async -> [String] {
        var components = URLComponents(string: "https://api.gbif.org/v1/occurrence/search")!
        components.queryItems = [
            URLQueryItem(name: "scientificName", value: scientificName),
            URLQueryItem(name: "country", value: "US"),
            URLQueryItem(name: "facet", value: "stateProvince"),
            URLQueryItem(name: "facetLimit", value: "60"),
            URLQueryItem(name: "limit", value: "0"),
        ]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let facets = json["facets"] as? [[String: Any]]
        else { return [] }

        let stateFacet = facets.first { facet in
            let field = (facet["field"] as? String)?.uppercased()
            return field == "STATE_PROVINCE"
        }

        guard let counts = stateFacet?["counts"] as? [[String: Any]] else { return [] }

        return counts.compactMap { entry in
            guard let name = entry["name"] as? String,
                  let count = entry["count"] as? Int, count > 0
            else { return nil }
            return name
        }
    }
}
