//
//  PlantydexApp.swift
//  Plantydex
//
//  Created by Zara Abraham on 1/2/26.
//

import SwiftUI

@main
struct PlantydexApp: App {
    @State private var selectedTab = 0

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
    }
}
