//
//  ReferenceImage.swift
//  Plantydex
//

import Foundation

/// A reference photo of a species that Pl@ntNet returns alongside an identification.
/// Stored on `Plant` as a Codable array so it syncs with the rest of the record.
struct ReferenceImage: Codable, Hashable {
    let organ: String?
    let author: String?
    let license: String?
    let url: String?
}
