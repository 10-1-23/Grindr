//
//  CascadeGridView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct CascadeGridView: View {
    @StateObject private var apiService = GrindrAPIService.shared
    @StateObject private var locationService = LocationService.shared
    
    @State private var profiles: [Profile] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var filterOnlineOnly: Bool = false
    @State private var selectedProfile: Profile? = nil
    @State private var currentPage: Int = 1
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var filteredProfiles: [Profile] {
        if filterOnlineOnly {
            return profiles.filter { $0.isOnline == true }
        }
        return profiles
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Radar Status Header
                    radarHeader
                    
                    if isLoading && profiles.isEmpty {
                        Spacer()
                        ProgressView()
                            .tint(Theme.accent)
                            .scaleEffect(1.2)
                        Text("Triangulating Cascade Grid...")
                            .font(Theme.fontMono)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.top, 10)
                        Spacer()
                    } else if let err = errorMessage, profiles.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                .font(.system(size: 44))
                                .foregroundColor(Theme.danger)
                            Text("Connection Error")
                                .font(Theme.fontHeadline)
                                .foregroundColor(Theme.textPrimary)
                            Text(err)
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Retry Scan") {
                                Task { await refreshGrid() }
                            }
                            .font(Theme.fontHeadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.accent)
                            .foregroundColor(Theme.background)
                            .cornerRadius(6)
                        }
                        Spacer()
                    } else {
                        // Profile Grid
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(filteredProfiles) { profile in
                                    ProfileCardView(profile: profile)
                                        .onTapGesture {
                                            selectedProfile = profile
                                        }
                                }
                            }
                            .padding(.horizontal, 2)
                            
                            // Bottom pagination trigger
                            if !profiles.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Theme.accent)
                                        .padding()
                                        .onAppear {
                                            loadMore()
                                        }
                                    Spacer()
                                }
                            }
                        }
                        .refreshable {
                            await refreshGrid()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedProfile) { profile in
                NavigationView {
                    ProfileDetailView(profile: profile)
                }
            }
        }
        .onAppear {
            if profiles.isEmpty {
                locationService.requestPermission()
                Task { await refreshGrid() }
            }
        }
    }
    
    // Top Bar Header
    private var radarHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(locationService.isSpoofingEnabled ? Theme.accent : Theme.onlineGreen)
                        .frame(width: 8, height: 8)
                    Text("GRINDRX")
                        .font(Theme.fontHeadline)
                        .foregroundColor(Theme.accent)
                    Text("SOVEREIGN")
                        .font(Theme.fontMono)
                        .foregroundColor(Theme.textMuted)
                }
                
                Text(locationService.isSpoofingEnabled ? "SPOOFED: \(String(format: "%.4f, %.4f", locationService.spoofedCoordinate.latitude, locationService.spoofedCoordinate.longitude))" : "\(profiles.count) PROFILES LOADED")
                    .font(Theme.fontMono)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            // Online Filter Pill
            Button(action: { filterOnlineOnly.toggle() }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(filterOnlineOnly ? Theme.onlineGreen : Theme.textMuted)
                        .frame(width: 6, height: 6)
                    Text("ONLINE")
                        .font(Theme.fontMono)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(filterOnlineOnly ? Theme.surfaceElevated : Theme.surface)
                .foregroundColor(filterOnlineOnly ? Theme.textPrimary : Theme.textMuted)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(filterOnlineOnly ? Theme.onlineGreen.opacity(0.5) : Theme.surfaceBorder, lineWidth: 1)
                )
            }
            
            // Refresh Button
            Button(action: { Task { await refreshGrid() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.accent)
                    .padding(8)
                    .background(Theme.surface)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Theme.surfaceBorder, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .overlay(
            Rectangle()
                .fill(Theme.surfaceBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private func refreshGrid() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        let coord = locationService.activeCoordinate
        do {
            let fetched = try await apiService.fetchCascade(latitude: coord.latitude, longitude: coord.longitude, page: 1)
            profiles = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func loadMore() {
        guard !isLoading else { return }
        currentPage += 1
        let coord = locationService.activeCoordinate
        Task {
            if let more = try? await apiService.fetchCascade(latitude: coord.latitude, longitude: coord.longitude, page: currentPage) {
                profiles.append(contentsOf: more)
            }
        }
    }
}
