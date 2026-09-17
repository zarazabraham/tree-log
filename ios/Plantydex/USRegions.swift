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
