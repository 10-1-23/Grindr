//
//  GrindrAPIService.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import Foundation
import Combine

@MainActor
final class GrindrAPIService: ObservableObject {
    static let shared = GrindrAPIService()
    
    @Published var authToken: String {
        didSet { UserDefaults.standard.set(authToken, forKey: "GrindrX_AuthToken") }
    }
    @Published var deviceId: String {
        didSet { UserDefaults.standard.set(deviceId, forKey: "GrindrX_DeviceId") }
    }
    @Published var currentProfileId: String {
        didSet { UserDefaults.standard.set(currentProfileId, forKey: "GrindrX_CurrentProfileId") }
    }
    @Published var isAuthenticated: Bool = false
    @Published var isOfflineDemoMode: Bool = false
    
    private let baseURL = URL(string: "https://grindr.mobi")!
    private let session: URLSession
    
    private init() {
        self.authToken = UserDefaults.standard.string(forKey: "GrindrX_AuthToken") ?? ""
        self.deviceId = UserDefaults.standard.string(forKey: "GrindrX_DeviceId") ?? UUID().uuidString.lowercased()
        self.currentProfileId = UserDefaults.standard.string(forKey: "GrindrX_CurrentProfileId") ?? ""
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        
        self.isAuthenticated = !self.authToken.isEmpty
    }
    
    // Generate new fake device identity
    func regenerateDeviceId() {
        self.deviceId = UUID().uuidString.lowercased()
    }
    
    // MARK: - Standard Headers
    private func buildRequest(for endpoint: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Spoof standard iOS Grindr headers
        request.setValue(authToken, forHTTPHeaderField: "L-Auth-Token")
        request.setValue(deviceId, forHTTPHeaderField: "L-Device-Id")
        request.setValue("Grindr/24.12.0 (iPhone; iOS 17.5; Scale/3.00)", forHTTPHeaderField: "User-Agent")
        request.setValue("24.12.0", forHTTPHeaderField: "X-Client-Version")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US", forHTTPHeaderField: "Accept-Language")
        
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    // MARK: - Cascade (Grid) Fetcher
    func fetchCascade(latitude: Double, longitude: Double, page: Int = 1) async throws -> [Profile] {
        if isOfflineDemoMode || authToken.isEmpty {
            return generateMockProfiles(latitude: latitude, longitude: longitude)
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("v3/cascade"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.6f", latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.6f", longitude)),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "nearbyGeoHash", value: "true")
        ]
        
        guard let url = components.url else { throw URLError(.badURL) }
        var req = buildRequest(for: "v3/cascade")
        req.url = url
        
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        if let cascadeResp = try? decoder.decode(CascadeResponse.self, from: data), let entries = cascadeResp.entries {
            return entries.compactMap { $0.profile }
        }
        
        // Fallback: direct array decode
        if let directProfiles = try? decoder.decode([Profile].self, from: data) {
            return directProfiles
        }
        
        return []
    }
    
    // MARK: - Full Profile Detail
    func fetchProfile(id: String) async throws -> Profile {
        if isOfflineDemoMode || authToken.isEmpty {
            return generateMockProfiles(latitude: 38.8951, longitude: -77.0364).first { $0.id == id } ?? generateMockProfiles(latitude: 38.8951, longitude: -77.0364)[0]
        }
        
        let req = buildRequest(for: "v4/profiles/\(id)")
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(Profile.self, from: data)
    }
    
    // MARK: - Send Tap
    func sendTap(recipientId: String, type: TapType) async throws -> Bool {
        let payload: [String: Any] = [
            "recipientId": recipientId,
            "tapType": type.rawValue
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let req = buildRequest(for: "v3/taps", method: "POST", body: data)
        
        let (_, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse else { return false }
        return (200...299).contains(httpResp.statusCode)
    }
    
    // MARK: - Inbox & Conversations
    func fetchInbox() async throws -> [ChatConversation] {
        if isOfflineDemoMode || authToken.isEmpty {
            return generateMockConversations()
        }
        
        let req = buildRequest(for: "v4/chat/inbox")
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return (try? JSONDecoder().decode([ChatConversation].self, from: data)) ?? []
    }
    
    // MARK: - Shared Albums
    func fetchSharedAlbums() async throws -> [GrindrAlbum] {
        if isOfflineDemoMode || authToken.isEmpty {
            return [
                GrindrAlbum(id: 101, title: "Vault 01", photos: [
                    AlbumContentItem(id: 1, mediaHash: "sample_hash_1", caption: "At the gym"),
                    AlbumContentItem(id: 2, mediaHash: "sample_hash_2", caption: "DC Skyline")
                ], ownerProfileId: "user_02", isSharedWithMe: true)
            ]
        }
        
        let req = buildRequest(for: "v2/albums/shares")
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return (try? JSONDecoder().decode([GrindrAlbum].self, from: data)) ?? []
    }
    
    // MARK: - Mock Demo Generator (Instant UI testing without live login)
    private func generateMockProfiles(latitude: Double, longitude: Double) -> [Profile] {
        [
            Profile(
                id: "1001",
                displayName: "Alex / Dev",
                aboutMe: "Swift & Systems Engineer. Into tech, gym, and good espresso. Ask for album.",
                age: 28,
                distance: 120.0,
                isOnline: true,
                lastActive: Date().millisecondsSince1970,
                mediaHash: nil,
                photos: [],
                tags: ["Tech", "Fitness", "Coffee", "Gamer"],
                ethnicity: "Mixed",
                relationshipStatus: "Single",
                bodyType: "Athletic",
                height: 182,
                weight: 80,
                position: "Vers",
                lookingFor: ["Dates", "Friends", "Right Now"],
                pronouns: "He/Him",
                meetAt: ["My place", "Bar"]
            ),
            Profile(
                id: "1002",
                displayName: "Marcus",
                aboutMe: "Architect in DC. Ruthless simplicity, Bauhaus design, and weekend hikes.",
                age: 32,
                distance: 450.0,
                isOnline: true,
                lastActive: Date().millisecondsSince1970 - 60000,
                mediaHash: nil,
                photos: [],
                tags: ["Design", "Art", "Travel"],
                ethnicity: "Black",
                relationshipStatus: "Single",
                bodyType: "Muscular",
                height: 188,
                weight: 88,
                position: "Top",
                lookingFor: ["Dates", "Networking"],
                pronouns: "He/Him",
                meetAt: ["Your place"]
            ),
            Profile(
                id: "1003",
                displayName: "Jordan",
                aboutMe: "Biotech researcher. Casual vibes, here for quick drinks or good chats.",
                age: 26,
                distance: 1250.0,
                isOnline: false,
                lastActive: Date().millisecondsSince1970 - 3600000,
                mediaHash: nil,
                photos: [],
                tags: ["Science", "Running", "Music"],
                ethnicity: "Latino",
                relationshipStatus: "Dating",
                bodyType: "Slim",
                height: 175,
                weight: 68,
                position: "Vers",
                lookingFor: ["Friends", "Chat"],
                pronouns: "He/Him",
                meetAt: ["Coffee shop"]
            ),
            Profile(
                id: "1004",
                displayName: "Dave R",
                aboutMe: "Cybersecurity analyst & ham radio enthusiast. Always building.",
                age: 30,
                distance: 3100.0,
                isOnline: true,
                lastActive: Date().millisecondsSince1970,
                mediaHash: nil,
                photos: [],
                tags: ["Infosec", "Crypto", "Tattoos"],
                ethnicity: "White",
                relationshipStatus: "Single",
                bodyType: "Average",
                height: 178,
                weight: 77,
                position: "Vers Bottom",
                lookingFor: ["Right Now", "Chat"],
                pronouns: "He/Him",
                meetAt: ["Anywhere"]
            )
        ]
    }
    
    private func generateMockConversations() -> [ChatConversation] {
        [
            ChatConversation(
                id: "conv_01",
                participantId: "1001",
                participantName: "Alex / Dev",
                participantMediaHash: nil,
                lastMessageSnippet: "Sent you an expiring photo 📸",
                lastMessageTimestamp: Date().millisecondsSince1970 - 120000,
                unreadCount: 1
            ),
            ChatConversation(
                id: "conv_02",
                participantId: "1002",
                participantName: "Marcus",
                participantMediaHash: nil,
                lastMessageSnippet: "Tapped you 🔥",
                lastMessageTimestamp: Date().millisecondsSince1970 - 1800000,
                unreadCount: 0
            )
        ]
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
}
