//
//  SharedAlbumsView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct SharedAlbumsView: View {
    @StateObject private var apiService = GrindrAPIService.shared
    @StateObject private var vaultService = PhotoVaultService.shared
    
    @State private var albums: [GrindrAlbum] = []
    @State private var isLoading: Bool = false
    @State private var selectedPhotoURL: URL? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SHARED ALBUMS")
                                .font(Theme.fontHeadline)
                                .foregroundColor(Theme.textPrimary)
                            Text("\(albums.count) ALBUMS UNLOCKED")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        
                        Button(action: { Task { await loadAlbums() } }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.accent)
                                .padding(8)
                                .background(Theme.surface)
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                    .background(Theme.surface)
                    .overlay(
                        Rectangle().fill(Theme.surfaceBorder).frame(height: 1),
                        alignment: .bottom
                    )
                    
                    if isLoading && albums.isEmpty {
                        Spacer()
                        ProgressView().tint(Theme.accent)
                        Spacer()
                    } else if albums.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "rectangle.stack.badge.person.crop")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.textMuted)
                            Text("No Shared Albums")
                                .font(Theme.fontHeadline)
                                .foregroundColor(Theme.textSecondary)
                            Text("When another profile shares an album, it will unlock here permanently.")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(albums) { album in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(album.title ?? "Shared Album")
                                                .font(Theme.fontHeadline)
                                                .foregroundColor(Theme.accent)
                                            Spacer()
                                            Text("\(album.photos?.count ?? 0) photos")
                                                .font(Theme.fontMono)
                                                .foregroundColor(Theme.textMuted)
                                        }
                                        
                                        if let photos = album.photos {
                                            LazyVGrid(columns: columns, spacing: 6) {
                                                ForEach(photos) { photo in
                                                    if let url = photo.url {
                                                        AsyncImage(url: url) { phase in
                                                            if let img = phase.image {
                                                                img
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(height: 160)
                                                                    .clipped()
                                                                    .cornerRadius(6)
                                                                    .onTapGesture {
                                                                        selectedPhotoURL = url
                                                                    }
                                                            } else {
                                                                Rectangle()
                                                                    .fill(Theme.surfaceElevated)
                                                                    .frame(height: 160)
                                                                    .cornerRadius(6)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Theme.surface)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.surfaceBorder, lineWidth: 1)
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: Binding<URLIdentifiable?>(
                get: { selectedPhotoURL != nil ? URLIdentifiable(url: selectedPhotoURL!) : nil },
                set: { selectedPhotoURL = $0?.url }
            )) { identifiable in
                photoFullSheet(for: identifiable.url)
            }
        }
        .onAppear {
            if albums.isEmpty {
                Task { await loadAlbums() }
            }
        }
    }
    
    private func photoFullSheet(for url: URL) -> some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") { selectedPhotoURL = nil }
                        .foregroundColor(Theme.accent)
                        .padding()
                }
                
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFit().padding()
                    } else {
                        ProgressView()
                    }
                }
                
                Button(action: {
                    Task {
                        _ = await vaultService.saveExpiringPhoto(
                            mediaId: Int64(abs(url.absoluteString.hashValue)),
                            senderId: "album",
                            urlString: url.absoluteString
                        )
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.to.line.circle.fill")
                        Text("SAVE TO VAULT")
                    }
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .cornerRadius(6)
                    .padding()
                }
                Spacer()
            }
        }
    }
    
    private func loadAlbums() async {
        isLoading = true
        if let fetched = try? await apiService.fetchSharedAlbums() {
            albums = fetched
        }
        isLoading = false
    }
}

struct URLIdentifiable: Identifiable {
    let id = UUID()
    let url: URL
}
