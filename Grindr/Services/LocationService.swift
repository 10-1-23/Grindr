//
//  LocationService.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 38.8951, longitude: -77.0364) // Washington DC default
    @Published var isSpoofingEnabled: Bool = false
    @Published var spoofedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 38.8951, longitude: -77.0364)
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    var activeCoordinate: CLLocationCoordinate2D {
        isSpoofingEnabled ? spoofedCoordinate : currentCoordinate
    }
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50.0
        
        let savedSpoof = UserDefaults.standard.bool(forKey: "GrindrX_IsSpoofing")
        self.isSpoofingEnabled = savedSpoof
        
        let lat = UserDefaults.standard.double(forKey: "GrindrX_SpoofLat")
        let lon = UserDefaults.standard.double(forKey: "GrindrX_SpoofLon")
        if lat != 0 && lon != 0 {
            self.spoofedCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func setSpoofLocation(latitude: Double, longitude: Double) {
        self.spoofedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.isSpoofingEnabled = true
        UserDefaults.standard.set(latitude, forKey: "GrindrX_SpoofLat")
        UserDefaults.standard.set(longitude, forKey: "GrindrX_SpoofLon")
        UserDefaults.standard.set(true, forKey: "GrindrX_IsSpoofing")
    }
    
    func disableSpoofing() {
        self.isSpoofingEnabled = false
        UserDefaults.standard.set(false, forKey: "GrindrX_IsSpoofing")
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentCoordinate = location.coordinate
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}
