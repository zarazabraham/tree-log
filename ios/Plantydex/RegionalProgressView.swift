//
//  RegionalProgressView.swift
//  Plantydex
//

import SwiftUI
import CoreLocation
import SwiftData

struct RegionalProgressView: View {
    @Environment(\.theme) private var theme
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = LocationManager()

    @Query private var plants: [Plant]

    // MARK: - State

    @State private var flora: RegionalFloraCache?
    @State private var loading = true
    @State private var error: String?

    // Region unlock state
    @State private var regionDiscoveryQueue: [USRegion] = []
    @State private var activeDiscovery: USRegion? = nil

    // Persisted set of already-acknowledged discoveries
    private let discoveredRegionsKey = "com.plantydex.discoveredRegionIds"
    private var savedDiscoveredIds: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: discoveredRegionsKey) ?? [])
    }

    // MARK: - Computed

    /// Distinct species collected. Plants are deduplicated by key for the same reason
    /// PlantLogView does it: CloudKit cannot enforce uniqueness across devices.
    private var collectedCount: Int {
        Set(plants.map(\.key)).count
    }

    private var progress: Double {
        guard let flora, flora.speciesCount > 0 else { return 0 }
        return min(Double(collectedCount) / Double(flora.speciesCount), 1.0)
    }

    private var unlockedRegionIds: Set<String> {
        Set(plants.flatMap(\.regionIds))
    }

    private var plantsPerRegion: [String: Int] {
        var counts: [String: Int] = [:]
        for plant in plants {
            for id in plant.regionIds { counts[id, default: 0] += 1 }
        }
        return counts
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                switch locationManager.authorizationStatus {
                case .denied, .restricted:
                    locationDeniedView
                default:
                    if loading {
                        DSLoadingState(message: "Finding your region...")
                    } else if let error {
                        DSErrorState(
                            title: "Could Not Load Region",
                            message: error,
                            retryAction: { Task { await fetchAll() } }
                        )
                    } else if let flora {
                        progressContent(flora: flora)
                    } else {
                        awaitingLocationView
                    }
                }
            }
            .navigationTitle("Region Progress")
            .task {
                locationManager.requestLocation()
                // Called unconditionally: fetchAll clears `loading` when there is no
                // location yet, so a failed or slow first fix shows the retry state
                // instead of spinning forever. onChange picks it up when a fix arrives.
                await fetchAll()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                guard let newLocation, flora == nil else { return }
                Task { await fetchAll(location: newLocation) }
            }
            .onChange(of: locationManager.authorizationStatus) { _, status in
                if status == .denied || status == .restricted { loading = false }
            }
            .fullScreenCover(item: $activeDiscovery) { region in
                RegionDiscoveryView(
                    region: region,
                    plantsHereCount: plantsPerRegion[region.id] ?? 0
                ) {
                    // Dismiss current; show next in queue
                    if regionDiscoveryQueue.isEmpty {
                        activeDiscovery = nil
                    } else {
                        activeDiscovery = regionDiscoveryQueue.removeFirst()
                    }
                }
            }
        }
    }

    // MARK: - Progress Content

    @ViewBuilder
    private func progressContent(flora: RegionalFloraCache) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.sectionSpacing) {

                // ── YOUR REGION ─────────────────────────────
                sectionHeader("Your Region")

                DSCard {
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: "location.fill")
                                .foregroundColor(theme.colors.primary)
                            Text(flora.projectName)
                                .font(theme.typography.headingSmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }

                        HStack(alignment: .lastTextBaseline, spacing: theme.spacing.xs) {
                            Text("\(collectedCount)")
                                .font(theme.typography.displayLarge)
                                .foregroundColor(theme.colors.primary)
                            Text("/ \(flora.speciesCount.formatted())")
                                .font(theme.typography.displaySmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }

                        Text("species collected in your region")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textTertiary)

                        progressBar(progress: progress, color: theme.colors.primary)

                        Text(progress.formatted(.percent.precision(.fractionLength(2))))
                            .font(theme.typography.captionMedium)
                            .foregroundColor(theme.colors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                HStack(spacing: theme.spacing.md) {
                    statCard(value: "\(collectedCount)", label: "Collected",
                             icon: "checkmark.circle.fill", color: theme.colors.success)
                    statCard(value: "\(max(flora.speciesCount - collectedCount, 0).formatted())",
                             label: "Remaining", icon: "leaf.circle", color: theme.colors.textTertiary)
                }

                // ── REGIONS GRID ─────────────────────────────
                HStack {
                    sectionHeader("US Regions")
                    Spacer()
                    Text("\(unlockedRegionIds.count) of \(USRegion.all.count) discovered")
                        .font(theme.typography.captionLarge)
                        .foregroundColor(theme.colors.textTertiary)
                }

                Text("Identify plants to unlock new regions. Travel to collect region-exclusive species.")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textTertiary)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: theme.spacing.md
                ) {
                    ForEach(USRegion.all) { region in
                        if unlockedRegionIds.contains(region.id) {
                            discoveredRegionCard(region)
                        } else {
                            lockedRegionCard
                        }
                    }
                }
            }
            .padding(theme.spacing.screenEdge)
        }
        .background(theme.colors.surfaceSecondary.ignoresSafeArea())
    }

    // MARK: - Discovered Region Card

    @ViewBuilder
    private func discoveredRegionCard(_ region: USRegion) -> some View {
        let plantsHere = plantsPerRegion[region.id] ?? 0
        let regionProgress = region.nativeSpeciesCount > 0
            ? min(Double(plantsHere) / Double(region.nativeSpeciesCount), 1.0)
            : 0.0
        let badge = badge(for: plantsHere)

        DSCard(elevation: .level1) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: region.icon)
                        .foregroundColor(region.color)
                        .font(.body)
                    Text(region.name)
                        .font(theme.typography.captionLargeEmphasized)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(theme.typography.captionSmall)
                    }
                }

                Text(region.states)
                    .font(theme.typography.captionSmall)
                    .foregroundColor(theme.colors.textTertiary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Spacer().frame(height: theme.spacing.xxs)

                Text("\(region.nativeSpeciesCount.formatted()) species")
                    .font(theme.typography.captionLargeEmphasized)
                    .foregroundColor(theme.colors.textPrimary)

                Text("\(plantsHere) of your plants here")
                    .font(theme.typography.captionSmall)
                    .foregroundColor(theme.colors.textSecondary)

                progressBar(progress: regionProgress, color: region.color, height: 6)

                Text(regionProgress.formatted(.percent.precision(.fractionLength(1))))
                    .font(theme.typography.captionSmall)
                    .foregroundColor(theme.colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Locked Region Card

    @ViewBuilder
    private var lockedRegionCard: some View {
        DSCard(elevation: .level1) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors.textTertiary)
                Text("???")
                    .font(theme.typography.headingMedium)
                    .foregroundColor(theme.colors.textTertiary)
                Text("Identify plants to\nunlock this region")
                    .font(theme.typography.captionSmall)
                    .foregroundColor(theme.colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
        }
        .opacity(0.55)
    }

    // MARK: - Shared Sub-views

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.headingMedium)
            .foregroundColor(theme.colors.textPrimary)
    }

    @ViewBuilder
    private func progressBar(progress: Double, color: Color, height: CGFloat = 10) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(theme.colors.surfaceSecondary)
                    .frame(height: height)
                if progress > 0 {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: height)
                }
            }
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        DSCard {
            VStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(value)
                    .font(theme.typography.headingLarge)
                    .foregroundColor(theme.colors.textPrimary)
                Text(label)
                    .font(theme.typography.captionMedium)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func badge(for plantsHere: Int) -> String? {
        if plantsHere >= 15 { return "⭐" }
        if plantsHere >= 5  { return "🌿" }
        return nil
    }

    // MARK: - Awaiting Location

    @ViewBuilder
    private var awaitingLocationView: some View {
        DSEmptyState(
            icon: "location.magnifyingglass",
            title: "Waiting for Location",
            message: "Plantydex needs a location fix to work out which region you're in.",
            actionTitle: "Try Again"
        ) {
            locationManager.requestLocation()
            Task { await fetchAll() }
        }
    }

    // MARK: - Location Denied

    @ViewBuilder
    private var locationDeniedView: some View {
        DSEmptyState(
            icon: "location.slash",
            title: "Location Access Needed",
            message: "Enable location access in Settings so Plantydex can show your regional plant progress.",
            actionTitle: "Open Settings"
        ) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        }
    }

    // MARK: - Data Fetching

    private func fetchAll(location: CLLocation? = nil) async {
        loading = true
        error = nil

        let loc = location ?? locationManager.location
        guard let loc else { loading = false; return }

        do {
            // The plant collection is already local; only the regional species count
            // needs the network, and only when the on-device cache has gone stale.
            flora = try await RegionService.regionalFlora(
                lat: loc.coordinate.latitude,
                lon: loc.coordinate.longitude,
                context: modelContext
            )

            // Distribution lookups hit GBIF directly and fail soft, so they never
            // take the screen down.
            await RegionService.refreshDistributions(for: plants, context: modelContext)
            checkForNewDiscoveries()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    // MARK: - Discovery Queue

    private func checkForNewDiscoveries() {
        let alreadySeen = savedDiscoveredIds
        let newlyUnlocked = unlockedRegionIds.subtracting(alreadySeen)

        // Persist all currently unlocked IDs
        let allUnlocked = savedDiscoveredIds.union(unlockedRegionIds)
        UserDefaults.standard.set(Array(allUnlocked), forKey: discoveredRegionsKey)

        guard !newlyUnlocked.isEmpty else { return }

        // Queue newly unlocked regions in the fixed geographic order
        let ordered = USRegion.all.filter { newlyUnlocked.contains($0.id) }
        regionDiscoveryQueue = Array(ordered.dropFirst())
        activeDiscovery = ordered.first
    }
}
