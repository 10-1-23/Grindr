//
//  SettingsView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    @StateObject private var apiService = GrindrAPIService.shared
    @StateObject private var locationService = LocationService.shared
    
    @State private var inputToken: String = ""
    @State private var customLat: String = ""
    @State private var customLon: String = ""
    @State private var toastMessage: String? = nil
    
    // Teleport Presets
    private let presets: [(name: String, lat: Double, lon: Double)] = [
        ("Washington DC", 38.8951, -77.0364),
        ("New York (Chelsea)", 40.7465, -74.0014),
        ("Los Angeles (WeHo)", 34.0900, -118.3617),
        ("Miami (South Beach)", 25.7826, -80.1341),
        ("London (Soho)", 51.5136, -0.1365),
        ("Paris (Le Marais)", 48.8575, 2.3585),
        ("Tokyo (Shinjuku)", 35.6938, 139.7034)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SOVEREIGN CONTROLS")
                                .font(Theme.fontHeadline)
                                .foregroundColor(Theme.accent)
                            Text("Hardware Identity, Session Auth & Teleporter")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // SECTION 1: GPS Teleporter
                        teleportSection
                        
                        // SECTION 2: Identity & Anti-Tracking
                        identitySection
                        
                        // SECTION 3: Session Authentication
                        authSection
                        
                        // SECTION 4: Developer Credentials & Team
                        devInfoSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .overlay(
                Group {
                    if let toast = toastMessage {
                        VStack {
                            Spacer()
                            Text(toast)
                                .font(Theme.fontMono)
                                .padding()
                                .background(Theme.surfaceElevated)
                                .foregroundColor(Theme.accent)
                                .cornerRadius(8)
                                .padding(.bottom, 30)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
        }
        .onAppear {
            inputToken = apiService.authToken
            customLat = String(format: "%.4f", locationService.activeCoordinate.latitude)
            customLon = String(format: "%.4f", locationService.activeCoordinate.longitude)
        }
    }
    
    // MARK: - Teleport Section
    private var teleportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.north.circle.fill")
                    .foregroundColor(locationService.isSpoofingEnabled ? Theme.accent : Theme.onlineGreen)
                Text("GLOBAL RADAR TELEPORTER")
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                
                if locationService.isSpoofingEnabled {
                    Button("Reset GPS") {
                        locationService.disableSpoofing()
                        showToast("Reset to actual GPS location")
                    }
                    .font(Theme.fontMono)
                    .foregroundColor(Theme.danger)
                }
            }
            
            Text("Active Coordinates: \(String(format: "%.4f, %.4f", locationService.activeCoordinate.latitude, locationService.activeCoordinate.longitude))")
                .font(Theme.fontMono)
                .foregroundColor(locationService.isSpoofingEnabled ? Theme.accent : Theme.textSecondary)
            
            // Preset Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("POPULAR TELEPORT NODES")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(presets, id: \.name) { preset in
                        Button(action: {
                            locationService.setSpoofLocation(latitude: preset.lat, longitude: preset.lon)
                            customLat = String(preset.lat)
                            customLon = String(preset.lon)
                            showToast("Teleported to \(preset.name)!")
                        }) {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption)
                                Text(preset.name)
                                    .font(Theme.fontMono)
                                    .lineLimit(1)
                            }
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Custom Lat/Lon
            HStack(spacing: 8) {
                TextField("Lat (e.g. 38.8951)", text: $customLat)
                    .font(Theme.fontMono)
                    .padding(8)
                    .background(Theme.surfaceElevated)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(4)
                
                TextField("Lon (e.g. -77.0364)", text: $customLon)
                    .font(Theme.fontMono)
                    .padding(8)
                    .background(Theme.surfaceElevated)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(4)
                
                Button("Go") {
                    if let lat = Double(customLat), let lon = Double(customLon) {
                        locationService.setSpoofLocation(latitude: lat, longitude: lon)
                        showToast("Teleported to custom GPS coordinates!")
                    }
                }
                .font(Theme.fontHeadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .foregroundColor(Theme.background)
                .cornerRadius(4)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.surfaceBorder, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Identity Section
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(Theme.accent)
                Text("HARDWARE IDENTITY MASK")
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT L-DEVICE-ID (SPOOFED UUID)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                
                Text(apiService.deviceId)
                    .font(Theme.fontMono)
                    .foregroundColor(Theme.accentSecondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceElevated)
                    .cornerRadius(4)
            }
            
            Button(action: {
                apiService.regenerateDeviceId()
                showToast("Generated fresh device identity UUID!")
            }) {
                HStack {
                    Image(systemName: "dice.fill")
                    Text("REGENERATE DEVICE IDENTITY")
                }
                .font(Theme.fontMono)
                .foregroundColor(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Theme.accent)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.surfaceBorder, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Auth Section
    private var authSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(Theme.accent)
                Text("SESSION AUTHENTICATION")
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)
            }
            
            Toggle(isOn: $apiService.isOfflineDemoMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Sandbox / Demo Mode")
                        .font(Theme.fontHeadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Simulates cascade and chats without connecting to live servers")
                        .font(Theme.fontMono)
                        .foregroundColor(Theme.textMuted)
                }
            }
            .tint(Theme.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("L-AUTH-TOKEN (PASTE FROM MITMPROXY OR LOGIN)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                
                TextField("Paste L-Auth-Token here...", text: $inputToken)
                    .font(Theme.fontMono)
                    .padding(8)
                    .background(Theme.surfaceElevated)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(4)
            }
            
            Button(action: {
                apiService.authToken = inputToken.trimmingCharacters(in: .whitespacesAndNewlines)
                showToast("Auth token updated successfully!")
            }) {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                    Text("SAVE AUTH TOKEN")
                }
                .font(Theme.fontHeadline)
                .foregroundColor(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Theme.accent)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.surfaceBorder, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Dev Info Section
    private var devInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DEPLOYMENT MANIFEST")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            
            VStack(spacing: 6) {
                manifestRow(key: "BUNDLE ID", value: "com.grindrguy.grindrx.Grindr")
                manifestRow(key: "DEV TEAM", value: "YA24JN93LX (LSJ Systems)")
                manifestRow(key: "VALIDITY", value: "365-Day Paid Developer Provision")
                manifestRow(key: "CLIENT ARCH", value: "Sovereign Bauhaus Swift / SwiftUI")
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.surfaceBorder, lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
    
    private func manifestRow(key: String, value: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Spacer()
            Text(value)
                .font(Theme.fontMono)
                .foregroundColor(Theme.textPrimary)
        }
    }
    
    private func showToast(_ text: String) {
        withAnimation { toastMessage = text }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { toastMessage = nil }
        }
    }
}
