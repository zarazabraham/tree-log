//
//  PlantydexApp.swift
//  Plantydex
//
//  Created by Zara Abraham on 1/2/26.
//

import SwiftUI
import SwiftData

@main
struct PlantydexApp: App {
    @State private var selectedTab = 0
    private let container = PlantydexApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            ThemeProvider {
                TabView(selection: $selectedTab) {
                    PlantLogView()
                        .tabItem {
                            Label("Log", systemImage: "list.bullet")
                        }
                        .tag(0)

                    PlantUploadView(selectedTab: $selectedTab)
                        .tabItem {
                            Label("Upload", systemImage: "plus.circle.fill")
                        }
                        .tag(1)

                    RegionalProgressView()
                        .tabItem {
                            Label("Progress", systemImage: "chart.bar.fill")
                        }
                        .tag(2)
                }
            }
        }
        .modelContainer(container)
    }

    /// Prefer a CloudKit-mirrored store. If that can't be set up (missing entitlement in a
    /// dev build, no iCloud account), fall back to a local-only store rather than refusing
    /// to launch — the user's data still works, it just doesn't sync.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Plant.self, Sighting.self, RegionalFloraCache.self])

        if let synced = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]
        ) {
            return synced
        }

        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .none)]
            )
        } catch {
            fatalError("Could not create the local model container: \(error)")
        }
    }
}
