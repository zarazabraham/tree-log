//
//  IdentifyService.swift
//  Plantydex
//

import CoreLocation
import Foundation
import SwiftData
import UIKit

/// Best match returned by the `identify-tree` edge function.
/// The function is a stateless Pl@ntNet proxy — nothing is persisted server-side,
/// so this is transport only; `IdentifyService` turns it into SwiftData records.
struct IdentifyResult: Decodable {
    let key: String
    let name: String
    let commonName: String?
    let scientificName: String?
    let genus: String?
    let family: String?
    let commonNames: [String]?
    let gbifId: String?
    let powoId: String?
    let iucnCategory: String?
    let confidence: Double?
    let referenceImages: [ReferenceImage]?
}

enum IdentifyError: LocalizedError {
    case unreadableImage
    case server(status: Int, message: String)
    case noMatch

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "That photo could not be read. Try a different one."
        case .noMatch:
            return "No plant matched this photo. Try a clearer shot of a leaf or flower."
        case let .server(status, message):
            return "Identification failed (\(status)): \(message)"
        }
    }
}

@MainActor
enum IdentifyService {
    /// Pl@ntNet gains nothing from a 12MP original, and a smaller body keeps the
    /// edge function well inside its request limits.
    private static let maxDimension: CGFloat = 1600
    private static let jpegQuality: CGFloat = 0.85

    /// Identifies a photo, then records it locally as a `Sighting` of a `Plant`.
    /// Returns the plant the sighting was attached to.
    static func identify(
        imageData: Data,
        location: CLLocation?,
        context: ModelContext
    ) async throws -> Plant {
        guard let jpeg = downscaledJPEG(from: imageData) else {
            throw IdentifyError.unreadableImage
        }

        let result = try await requestIdentification(jpeg: jpeg)
        return store(result: result, photo: jpeg, location: location, context: context)
    }

    // MARK: - Image preparation

    static func downscaledJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else {
            return image.jpegData(compressionQuality: jpegQuality)
        }

        let scale = maxDimension / longestSide
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: jpegQuality)
    }

    // MARK: - Network

    private static func requestIdentification(jpeg: Data, organ: String = "leaf") async throws -> IdentifyResult {
        let url = SupabaseConfig.url.appendingPathComponent("functions/v1/identify-tree")
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = multipartBody(boundary: boundary, jpeg: jpeg, organ: organ)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw IdentifyError.server(status: -1, message: "Invalid response")
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 404 { throw IdentifyError.noMatch }
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw IdentifyError.server(status: http.statusCode, message: message)
        }

        return try JSONDecoder().decode(IdentifyResult.self, from: data)
    }

    private static func multipartBody(boundary: String, jpeg: Data, organ: String) -> Data {
        var body = Data()

        func append(_ string: String) {
            body.append(Data(string.utf8))
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"image\"; filename=\"plant.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(jpeg)
        append("\r\n")

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"organ\"\r\n\r\n")
        append("\(organ)\r\n")

        append("--\(boundary)--\r\n")
        return body
    }

    // MARK: - Persistence

    /// Finds the existing `Plant` for this species or creates one, then attaches a sighting.
    ///
    /// CloudKit forbids unique constraints, so identity is enforced here rather than by the
    /// schema. Two offline devices identifying the same species can still produce duplicate
    /// keys after sync; `PlantLogView` groups by key on read so the log stays correct.
    private static func store(
        result: IdentifyResult,
        photo: Data,
        location: CLLocation?,
        context: ModelContext
    ) -> Plant {
        let key = result.key
        var descriptor = FetchDescriptor<Plant>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1

        let plant: Plant
        if let existing = try? context.fetch(descriptor).first {
            plant = existing
        } else {
            plant = Plant(
                key: result.key,
                commonName: result.commonName ?? result.name,
                scientificName: result.scientificName,
                family: result.family,
                genus: result.genus,
                commonNames: result.commonNames ?? [],
                gbifId: result.gbifId,
                powoId: result.powoId,
                iucnCategory: result.iucnCategory,
                referenceImages: result.referenceImages ?? []
            )
            context.insert(plant)
        }

        let sighting = Sighting(
            photo: photo,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            confidence: result.confidence,
            plant: plant
        )
        context.insert(sighting)

        plant.lastSeenAt = sighting.createdAt
        plant.sightingCount += 1

        try? context.save()
        return plant
    }
}
