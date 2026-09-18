//
//  SupabaseConfig.swift
//  Plantydex
//
//  Created by Zara Abraham on 1/2/26.
//
//  All user data lives on the device in SwiftData. The only reason this app talks to a
//  server at all is that the Pl@ntNet API key cannot ship inside the bundle, so two
//  stateless edge functions hold it: identify-tree and get-regional-flora.
//

import Foundation

enum SupabaseConfig {
    /// Backend base URL, supplied by Config.xcconfig via Info.plist.
    static var url: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SB_URL") as? String,
              !raw.isEmpty,
              !raw.hasPrefix("$"),
              let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            fatalError(
                "SB_URL is missing or malformed. Copy Config.example.xcconfig to "
                + "Config.xcconfig and set SB_URL."
            )
        }
        return url
    }

    /// Publishable (anon) key. Safe to ship — it grants nothing beyond invoking the
    /// two public edge functions.
    static var anonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SB_ANON_KEY") as? String,
              !key.isEmpty,
              !key.hasPrefix("$")
        else {
            fatalError(
                "SB_ANON_KEY is missing. Copy Config.example.xcconfig to "
                + "Config.xcconfig and set SB_ANON_KEY."
            )
        }
        return key
    }
}
