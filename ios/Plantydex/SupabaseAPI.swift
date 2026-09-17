//
//  SupabaseAPI.swift
//  Plantydex
//
//  Created by Zara Abraham on 1/2/26.
//
import Foundation

enum SupabaseConfig {
    static var url: URL {
        // Try to read from Info.plist first
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SB_URL") as? String,
           !raw.isEmpty,
           !raw.hasPrefix("$"),
           let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            print("DEBUG: Loaded SB_URL from Info.plist: \(url)")
            return url
        }

        // Fallback to hardcoded value for development
        // IMPORTANT: Replace this with your actual Supabase URL
        let fallback = "http://127.0.0.1:54321"
        print("DEBUG: Using fallback SB_URL: \(fallback)")
        print("WARNING: SB_URL not found in Info.plist. Using hardcoded fallback.")
        print("To fix: Set SB_URL in Info.plist or configure Config.xcconfig in Xcode project settings")

        guard let url = URL(string: fallback) else {
            fatalError("Invalid fallback URL: \(fallback)")
        }
        return url
    }

    static var anonKey: String {
        // Try to read from Info.plist first
        if let key = Bundle.main.object(forInfoDictionaryKey: "SB_ANON_KEY") as? String,
           !key.isEmpty,
           !key.hasPrefix("$") {
            print("DEBUG: Loaded SB_ANON_KEY from Info.plist")
            return key
        }

        // Fallback to hardcoded value for development
        // IMPORTANT: Replace this with your actual anon key
        let fallback = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
        print("DEBUG: Using fallback SB_ANON_KEY")
        print("WARNING: SB_ANON_KEY not found in Info.plist. Using hardcoded fallback.")
        print("To fix: Set SB_ANON_KEY in Info.plist or configure Config.xcconfig in Xcode project settings")

        return fallback
    }
}

struct PlantDistribution: Decodable {
    let plantKey: String
    let regionIds: [String]
}

struct RegionalFloraResult: Decodable {
    let projectId: String
    let projectName: String
    let speciesCount: Int
    let fromCache: Bool
}

struct PlantLogRow: Identifiable, Decodable {
    // `plant_log` view columns (from your swagger)
    let key: String
    let name: String?
    let sightings_count: Int
    let last_seen: String?
    let thumbnail_url: String?

    var id: String { key }
}

final class SupabaseAPI {
    static let shared = SupabaseAPI()
    private init() {}

    func fetchPlantLog() async throws -> [PlantLogRow] {
        // GET /rest/v1/plant_log?select=...&order=last_seen.desc
        let baseURL = SupabaseConfig.url
        let fullURL = baseURL.appendingPathComponent("rest/v1/plant_log")

        print("DEBUG: Base URL: \(baseURL)")
        print("DEBUG: Full URL before query: \(fullURL)")

        guard var comps = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create URLComponents from: \(fullURL)"
            ])
        }

        comps.queryItems = [
            URLQueryItem(name: "select", value: "key,name,sightings_count,last_seen,thumbnail_url"),
            URLQueryItem(name: "order", value: "last_seen.desc")
        ]

        guard let finalURL = comps.url else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to build final URL with query params"
            ])
        }

        print("DEBUG: Final URL: \(finalURL)")

        var req = URLRequest(url: finalURL)
        req.httpMethod = "GET"
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        print("DEBUG: Making request to: \(finalURL)")

        let (data, resp) = try await URLSession.shared.data(for: req)

        print("DEBUG: Response received")

        if let http = resp as? HTTPURLResponse {
            print("DEBUG: Status code: \(http.statusCode)")
            let body = String(data: data, encoding: .utf8) ?? ""
            print("DEBUG: Response body: \(body)")

            if !(200...299).contains(http.statusCode) {
                throw NSError(domain: "SupabaseAPI", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Supabase error \(http.statusCode): \(body)"
                ])
            }
        }

        return try JSONDecoder().decode([PlantLogRow].self, from: data)
    }

    func fetchPlantLogRow(key: String) async throws -> PlantLogRow {
        let baseURL = SupabaseConfig.url
        let fullURL = baseURL.appendingPathComponent("rest/v1/plant_log")

        guard var comps = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create URLComponents"
            ])
        }

        comps.queryItems = [
            URLQueryItem(name: "key", value: "eq.\(key)"),
            URLQueryItem(name: "select", value: "key,name,sightings_count,last_seen,thumbnail_url")
        ]

        guard let finalURL = comps.url else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to build URL"
            ])
        }

        var req = URLRequest(url: finalURL)
        req.httpMethod = "GET"
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "SupabaseAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Error \(http.statusCode): \(body)"
            ])
        }

        let rows = try JSONDecoder().decode([PlantLogRow].self, from: data)
        guard let row = rows.first else {
            throw NSError(domain: "SupabaseAPI", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Plant not found"
            ])
        }
        return row
    }

    func fetchPlant(key: String) async throws -> PlantData? {
        let keyLc = key.lowercased()
        let baseURL = SupabaseConfig.url
        let fullURL = baseURL.appendingPathComponent("rest/v1/plants")

        guard var comps = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create URLComponents"
            ])
        }

        comps.queryItems = [
            URLQueryItem(name: "key_lc", value: "eq.\(keyLc)"),
            URLQueryItem(name: "select", value: "key,common_name,scientific_name,family,genus,reference_images,plant_details")
        ]

        guard let finalURL = comps.url else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to build URL"
            ])
        }

        var req = URLRequest(url: finalURL)
        req.httpMethod = "GET"
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "SupabaseAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Error \(http.statusCode): \(body)"
            ])
        }

        // Debug raw response
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        print("DEBUG fetchPlant: Response body: \(responseBody)")

        let rows = try JSONDecoder().decode([PlantData].self, from: data)
        if let first = rows.first {
            print("DEBUG fetchPlant: Decoded plant with key: \(first.key)")
            print("DEBUG fetchPlant: reference_images count: \(first.reference_images?.count ?? 0)")
        }
        return rows.first
    }

    func fetchOrCreateTreeEntry(key: String) async throws -> TreeEntry {
        let baseURL = SupabaseConfig.url
        let fullURL = baseURL.appendingPathComponent("rest/v1/tree_entries")

        // Try to fetch first
        guard var comps = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create URLComponents"
            ])
        }

        comps.queryItems = [
            URLQueryItem(name: "key", value: "eq.\(key)"),
            URLQueryItem(name: "select", value: "key,display_name,notes,updated_at,created_at")
        ]

        guard let fetchURL = comps.url else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to build URL"
            ])
        }

        var fetchReq = URLRequest(url: fetchURL)
        fetchReq.httpMethod = "GET"
        fetchReq.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        fetchReq.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        fetchReq.setValue("application/json", forHTTPHeaderField: "Accept")

        let (fetchData, fetchResp) = try await URLSession.shared.data(for: fetchReq)

        if let http = fetchResp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
            let rows = try JSONDecoder().decode([TreeEntry].self, from: fetchData)
            if let existing = rows.first {
                return existing
            }
        }

        // Create if doesn't exist
        var createReq = URLRequest(url: fullURL)
        createReq.httpMethod = "POST"
        createReq.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        createReq.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        createReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createReq.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = ["key": key]
        createReq.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (createData, createResp) = try await URLSession.shared.data(for: createReq)

        if let http = createResp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let errorBody = String(data: createData, encoding: .utf8) ?? ""
            throw NSError(domain: "SupabaseAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Error \(http.statusCode): \(errorBody)"
            ])
        }

        let created = try JSONDecoder().decode([TreeEntry].self, from: createData)
        guard let entry = created.first else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create entry"
            ])
        }
        return entry
    }

    func fetchRegionalFlora(lat: Double, lon: Double) async throws -> RegionalFloraResult {
        let url = SupabaseConfig.url.appendingPathComponent("functions/v1/get-regional-flora")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["lat": lat, "lon": lon])

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "SupabaseAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "fetchRegionalFlora error \(http.statusCode): \(body)"
            ])
        }

        return try JSONDecoder().decode(RegionalFloraResult.self, from: data)
    }

    func fetchPlantDistributions(plantKeys: [String]) async throws -> [PlantDistribution] {
        guard !plantKeys.isEmpty else { return [] }
        let url = SupabaseConfig.url.appendingPathComponent("functions/v1/get-plant-distribution")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["plantKeys": plantKeys])

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "SupabaseAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "fetchPlantDistributions error \(http.statusCode): \(body)"
            ])
        }

        return try JSONDecoder().decode([PlantDistribution].self, from: data)
    }

    func updateTreeEntry(key: String, displayName: String?, notes: String?) async throws {
        let baseURL = SupabaseConfig.url
        let fullURL = baseURL.appendingPathComponent("rest/v1/tree_entries")

        guard var comps = URLComponents(url: fullURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create URLComponents"
            ])
        }

        comps.queryItems = [URLQueryItem(name: "key", value: "eq.\(key)")]

        guard let finalURL = comps.url else {
            throw NSError(domain: "SupabaseAPI", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to build URL"
            ])
        }

        var req = URLRequest(url: finalURL)
        req.httpMethod = "PATCH"
        req.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any?] = [:]
        body["display_name"] = displayName
        body["notes"] = notes
        body["updated_at"] = ISO8601DateFormatter().string(from: Date())

        req.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

        let (data, resp) = try await URLSession.shared.data(for: req)

        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "SupabaseAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Error \(http.statusCode): \(errorBody)"
            ])
        }
    }
}
