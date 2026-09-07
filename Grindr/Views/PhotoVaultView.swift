//
//  PhotoVaultView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct PhotoVaultView: View {
    @StateObject private var vaultService = PhotoVaultService.shared
    @State private var selectedMedia: SavedVaultMedia? = nil
    @State private var exportToast: String? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
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
                            HStack(spacing: 6) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(Theme.accent)
                                Text("VAULT ARCHIVE")
                                    .font(Theme.fontHeadline)
                                    .foregroundColor(Theme.textPrimary)
                            }
                            Text("\(vaultService.savedItems.count) EXPIRING MEDIA PRESERVED")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Theme.surface)
                    .overlay(
                        Rectangle().fill(Theme.surfaceBorder).frame(height: 1),
                        alignment: .bottom
                    )
                    
                    if vaultService.savedItems.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "timer")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.textMuted)
                            Text("No Expiring Media Captured Yet")
                                .font(Theme.fontHeadline)
                                .foregroundColor(Theme.textPrimary)
                            Text("When someone sends an expiring photo, open the chat and tap 'Save to Vault' to permanently store it here.")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(vaultService.savedItems) { item in
                                    vaultThumbnail(for: item)
                                        .onTapGesture {
                                            selectedMedia = item
                                        }
                                }
                            }
                            .padding(4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedMedia) { item in
                vaultDetailSheet(for: item)
            }
            .overlay(
                Group {
                    if let toast = exportToast {
                        VStack {
                            Spacer()
                            Text(toast)
                                .font(Theme.fontMono)
                                .padding()
                                .background(Theme.surfaceElevated)
                                .foregroundColor(Theme.accent)
                                .cornerRadius(8)
                                .padding(.bottom, 40)
                        }
                    }
                }
            )
        }
    }
    
    private func vaultThumbnail(for item: SavedVaultMedia) -> some View {
        ZStack(alignment: .topTrailing) {
            let fileURL = vaultService.getLocalImageURL(for: item)
            if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fill)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Theme.surfaceElevated)
                    .aspectRatio(1.0, contentMode: .fill)
                    .overlay(ProgressView())
            }
            
            // "Expiring" Badge Tag
            Image(systemName: "timer")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.background)
                .padding(4)
                .background(Theme.danger)
                .clipShape(Circle())
                .padding(4)
        }
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.surfaceBorder, lineWidth: 0.8)
        )
    }
    
    private func vaultDetailSheet(for item: SavedVaultMedia) -> some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("VAULT INSPECTOR")
                        .font(Theme.fontHeadline)
                        .foregroundColor(Theme.accent)
                    Spacer()
                    Button("Done") { selectedMedia = nil }
                        .foregroundColor(Theme.textPrimary)
                }
                .padding()
                
                let fileURL = vaultService.getLocalImageURL(for: item)
                if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 8) {
                    Text("CAPTURED: \(item.timestamp.formatted())")
                        .font(Theme.fontMono)
                        .foregroundColor(Theme.textSecondary)
                    Text("MEDIA ID: \(item.mediaId)")
                        .font(Theme.fontMono)
                        .foregroundColor(Theme.textMuted)
                }
                
                Button(action: {
                    Task {
                        let success = await vaultService.exportToCameraRoll(item: item)
                        exportToast = success ? "Saved to Camera Roll!" : "Export failed"
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        exportToast = nil
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("EXPORT TO CAMERA ROLL")
                    }
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .cornerRadius(6)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
    }
}
