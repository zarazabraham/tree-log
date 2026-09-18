//
//  LocationManager.swift
//  Plantydex
//

import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var lastError: Error?
    @Published var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // city-level is enough for flora regions
        manager.distanceFilter = 50_000 // only update after 50 km movement
    }

    func requestLocation() {
        lastError = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            manager.requestLocation()
#if os(iOS)
        case .authorizedWhenInUse:
            manager.requestLocation()
#endif
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
#if os(iOS)
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
#else
        if authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
#endif
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // requestLocation() delivers exactly one fix or one failure, so a transient
        // failure would otherwise leave callers waiting forever. Record it; the
        // Progress tab shows a retry rather than an endless spinner.
        lastError = error
    }
}
