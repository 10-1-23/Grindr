//
//  PhotoVaultService.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import Foundation
import UIKit
import Photos
import Combine

struct SavedVaultMedia: Identifiable, Codable {
    let id: String
    let mediaId: Int64
    let senderId: String
    let originalURL: String
    let localFileName: String
    let timestamp: Date
    var isExpiring: Bool
}

@MainActor
final class PhotoVaultService: ObservableObject {
    static let shared = PhotoVaultService()
    
    @Published var savedItems: [SavedVaultMedia] = []
    
    private let fileManager = FileManager.default
    private var vaultDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("PhotoVault", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {
        loadSavedItems()
    }
    
    func saveExpiringPhoto(mediaId: Int64, senderId: String, urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let fileName = "\(mediaId)_\(UUID().uuidString.prefix(6)).jpg"
            let localURL = vaultDirectory.appendingPathComponent(fileName)
            
            try data.write(to: localURL)
            
            let item = SavedVaultMedia(
                id: UUID().uuidString,
                mediaId: mediaId,
                senderId: senderId,
                originalURL: urlString,
                localFileName: fileName,
                timestamp: Date(),
                isExpiring: true
            )
            savedItems.insert(item, at: 0)
            persistMetadata()
            return true
        } catch {
            print("PhotoVault error saving image:", error)
            return false
        }
    }
    
    func exportToCameraRoll(item: SavedVaultMedia) async -> Bool {
        let localURL = vaultDirectory.appendingPathComponent(item.localFileName)
        guard let image = UIImage(contentsOfFile: localURL.path) else { return false }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: false)
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func getLocalImageURL(for item: SavedVaultMedia) -> URL {
        vaultDirectory.appendingPathComponent(item.localFileName)
    }
    
    private func persistMetadata() {
        let metaURL = vaultDirectory.appendingPathComponent("metadata.json")
        if let data = try? JSONEncoder().encode(savedItems) {
            try? data.write(to: metaURL)
        }
    }
    
    private func loadSavedItems() {
        let metaURL = vaultDirectory.appendingPathComponent("metadata.json")
        guard let data = try? Data(contentsOf: metaURL),
              let items = try? JSONDecoder().decode([SavedVaultMedia].self, from: data) else {
            return
        }
        self.savedItems = items
    }
}
