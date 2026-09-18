//
//  USRegions.swift
//  Plantydex
//
//  Static native plant species counts sourced from:
//  NatureServe "States of the Union" (2002), BONAP, Jepson Flora Project,
//  USDA PLANTS Database, and state herbarium surveys.
//  Counts represent approximate unique native vascular plant species per region.
//

import SwiftUI

struct USRegion: Identifiable {
    let id: String
    let name: String
    let states: String
    let icon: String       // SF Symbol name
    let color: Color
    let nativeSpeciesCount: Int
}

extension USRegion {
    static let all: [USRegion] = [
        USRegion(
            id: "pacific-northwest",
            name: "Pacific Northwest",
            states: "WA · OR",
            icon: "tree.fill",
            color: .teal,
            nativeSpeciesCount: 3_200
        ),
        USRegion(
            id: "california",
            name: "California",
            states: "CA",
            icon: "sun.max.fill",
            color: .orange,
            nativeSpeciesCount: 5_400
        ),
        USRegion(
            id: "mountain-west",
            name: "Mountain West",
            states: "CO · UT · NV · ID · MT · WY",
            icon: "mountain.2.fill",
            color: .purple,
            nativeSpeciesCount: 4_800
        ),
        USRegion(
            id: "desert-southwest",
            name: "Desert Southwest",
            states: "AZ · NM",
            icon: "sun.dust.fill",
            color: Color(red: 0.85, green: 0.55, blue: 0.2),
            nativeSpeciesCount: 4_800
        ),
        USRegion(
            id: "great-plains",
            name: "Great Plains",
            states: "ND · SD · NE · KS · OK",
            icon: "wind",
            color: .yellow,
            nativeSpeciesCount: 3_800
        ),
        USRegion(
            id: "midwest",
            name: "Midwest",
            states: "MN · WI · MI · IL · IN · OH · IA · MO",
            icon: "leaf.fill",
            color: .green,
            nativeSpeciesCount: 4_200
        ),
        USRegion(
            id: "northeast",
            name: "Northeast",
            states: "ME · NH · VT · MA · RI · CT · NY · PA · NJ",
            icon: "snowflake",
            color: .blue,
            nativeSpeciesCount: 3_500
        ),
        USRegion(
            id: "mid-atlantic-appalachia",
            name: "Appalachia",
            states: "DE · MD · VA · WV · NC · SC",
            icon: "mountain.2",
            color: Color(red: 0.4, green: 0.6, blue: 0.3),
            nativeSpeciesCount: 4_300
        ),
        USRegion(
            id: "southeast",
            name: "Southeast",
            states: "GA · FL · AL · MS · LA · AR",
            icon: "drop.fill",
            color: Color(red: 0.2, green: 0.6, blue: 0.5),
            nativeSpeciesCount: 5_200
        ),
        USRegion(
            id: "texas",
            name: "Texas & Gulf",
            states: "TX",
            icon: "star.fill",
            color: Color(red: 0.8, green: 0.2, blue: 0.2),
            nativeSpeciesCount: 5_000
        ),
        USRegion(
            id: "alaska",
            name: "Alaska",
            states: "AK",
            icon: "snowflake.circle.fill",
            color: Color(red: 0.4, green: 0.6, blue: 0.8),
            nativeSpeciesCount: 1_500
        ),
        USRegion(
            id: "hawaii",
            name: "Hawaiʻi",
            states: "HI",
            icon: "flame.fill",
            color: Color(red: 0.9, green: 0.3, blue: 0.4),
            nativeSpeciesCount: 1_400
        ),
    ]
}

// MARK: - GBIF state mapping

extension USRegion {
    /// Maps a GBIF `stateProvince` facet value (lowercased) to a region id.
    ///
    /// Ported from the former get-plant-distribution edge function; the device now
    /// queries GBIF directly, since that API needs no key.
    ///
    /// NOTE: this covers 48 states. Kentucky and Tennessee belong to no region here,
    /// matching the original server-side table — a species recorded only in KY/TN
    /// unlocks nothing. Add them to a region (and to that region's `states` string)
    /// to close the gap.
    static let stateToRegionId: [String: String] = [
        "washington": "pacific-northwest",
        "oregon": "pacific-northwest",
        "california": "california",
        "colorado": "mountain-west",
        "utah": "mountain-west",
        "nevada": "mountain-west",
        "idaho": "mountain-west",
        "montana": "mountain-west",
        "wyoming": "mountain-west",
        "arizona": "desert-southwest",
        "new mexico": "desert-southwest",
        "north dakota": "great-plains",
        "south dakota": "great-plains",
        "nebraska": "great-plains",
        "kansas": "great-plains",
        "oklahoma": "great-plains",
        "minnesota": "midwest",
        "wisconsin": "midwest",
        "michigan": "midwest",
        "illinois": "midwest",
        "indiana": "midwest",
        "ohio": "midwest",
        "iowa": "midwest",
        "missouri": "midwest",
        "maine": "northeast",
        "new hampshire": "northeast",
        "vermont": "northeast",
        "massachusetts": "northeast",
        "rhode island": "northeast",
        "connecticut": "northeast",
        "new york": "northeast",
        "pennsylvania": "northeast",
        "new jersey": "northeast",
        "delaware": "mid-atlantic-appalachia",
        "maryland": "mid-atlantic-appalachia",
        "virginia": "mid-atlantic-appalachia",
        "west virginia": "mid-atlantic-appalachia",
        "north carolina": "mid-atlantic-appalachia",
        "south carolina": "mid-atlantic-appalachia",
        "georgia": "southeast",
        "florida": "southeast",
        "alabama": "southeast",
        "mississippi": "southeast",
        "louisiana": "southeast",
        "arkansas": "southeast",
        "texas": "texas",
        "alaska": "alaska",
        "hawaii": "hawaii",
    ]

    /// Collapses GBIF state names into the set of regions they belong to.
    static func regionIds(forStateNames names: [String]) -> [String] {
        var ids = Set<String>()
        for name in names {
            if let id = stateToRegionId[name.trimmingCharacters(in: .whitespaces).lowercased()] {
                ids.insert(id)
            }
        }
        return Array(ids)
    }
}
