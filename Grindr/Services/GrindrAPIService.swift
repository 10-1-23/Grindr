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
    
    func regenerateDeviceId() {
        self.deviceId = UUID().uuidString.lowercased()
    }
    
    private func buildRequest(for endpoint: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
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
                GrindrAlbum(id: 101, title: "DC Nights & Gym", photos: [
                    AlbumContentItem(id: 1, mediaHash: nil, customURL: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800", caption: "At the gym"),
                    AlbumContentItem(id: 2, mediaHash: nil, customURL: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800", caption: "DC Skyline")
                ], ownerProfileId: "1002", isSharedWithMe: true)
            ]
        }
        
        let req = buildRequest(for: "v2/albums/shares")
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return (try? JSONDecoder().decode([GrindrAlbum].self, from: data)) ?? []
    }
    
    // MARK: - Current User Profile (Me)
    func fetchMyProfile() async throws -> Profile {
        if isOfflineDemoMode || authToken.isEmpty {
            return generateMockProfiles(latitude: 38.8951, longitude: -77.0364)[0]
        }
        
        let req = buildRequest(for: "v4/me/profile")
        let (data, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Profile.self, from: data)
    }

    // MARK: - Direct Chat Messaging
    func sendMessage(recipientId: String, body: String) async throws -> Bool {
        if isOfflineDemoMode || authToken.isEmpty {
            return true
        }
        
        let payload: [String: Any] = [
            "recipientId": recipientId,
            "body": body,
            "type": "text"
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let req = buildRequest(for: "v4/chat/messages", method: "POST", body: data)
        let (_, response) = try await session.data(for: req)
        guard let httpResp = response as? HTTPURLResponse else { return false }
        return (200...299).contains(httpResp.statusCode)
    }

    // MARK: - Sync Session from Local Dokk Proxy
    func syncSessionFromDokk(host: String = "192.168.1.243", port: Int = 8080) async throws -> Bool {
        guard let url = URL(string: "http://\(host):\(port)/api/grindrx/session") else { return false }
        let (data, response) = try await session.data(from: url)
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else { return false }
        
        struct DokkSessionResponse: Codable {
            let success: Bool
            let session: SessionData?
            struct SessionData: Codable {
                let authToken: String
                let deviceId: String
            }
        }
        
        if let decoded = try? JSONDecoder().decode(DokkSessionResponse.self, from: data),
           let sess = decoded.session, !sess.authToken.isEmpty {
            self.authToken = sess.authToken
            if !sess.deviceId.isEmpty {
                self.deviceId = sess.deviceId
            }
            self.isAuthenticated = true
            return true
        }
        return false
    }
    
    // MARK: - High-Resolution Demo Profiles with Images
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
                customImageURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
                photos: [
                    ProfilePhoto(id: "p1", mediaHash: nil, customURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800", caption: "DC rooftop"),
                    ProfilePhoto(id: "p2", mediaHash: nil, customURL: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800", caption: "Weekend vibes")
                ],
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
                customImageURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                photos: [
                    ProfilePhoto(id: "p3", mediaHash: nil, customURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800", caption: "Studio work"),
                    ProfilePhoto(id: "p4", mediaHash: nil, customURL: "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=800", caption: "Hiking")
                ],
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
                customImageURL: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800",
                photos: [
                    ProfilePhoto(id: "p5", mediaHash: nil, customURL: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800", caption: "Lab life")
                ],
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
                customImageURL: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800",
                photos: [
                    ProfilePhoto(id: "p6", mediaHash: nil, customURL: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800", caption: "Desk setup")
                ],
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
            ),
            Profile(
                id: "1005",
                displayName: "Kai",
                aboutMe: "Photographer & creative director. Looking for interesting people.",
                age: 25,
                distance: 4200.0,
                isOnline: true,
                lastActive: Date().millisecondsSince1970,
                mediaHash: nil,
                customImageURL: "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=800",
                photos: [],
                tags: ["Photo", "Nightlife", "Travel"],
                ethnicity: "Asian",
                relationshipStatus: "Single",
                bodyType: "Fit",
                height: 177,
                weight: 72,
                position: "Vers",
                lookingFor: ["Dates", "Right Now"],
                pronouns: "He/Him",
                meetAt: ["Bar"]
            ),
            Profile(
                id: "1006",
                displayName: "Tyler M",
                aboutMe: "Personal trainer. Up early, lifting heavy. Let's grab a smoothie.",
                age: 29,
                distance: 5800.0,
                isOnline: false,
                lastActive: Date().millisecondsSince1970 - 7200000,
                mediaHash: nil,
                customImageURL: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800",
                photos: [],
                tags: ["Gym", "Nutrition", "Outdoors"],
                ethnicity: "White",
                relationshipStatus: "Single",
                bodyType: "Muscular",
                height: 185,
                weight: 90,
                position: "Top",
                lookingFor: ["Workout Partner", "Dates"],
                pronouns: "He/Him",
                meetAt: ["Gym"]
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
                participantCustomURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
                lastMessageSnippet: "Sent you an expiring photo 📸",
                lastMessageTimestamp: Date().millisecondsSince1970 - 120000,
                unreadCount: 1
            ),
            ChatConversation(
                id: "conv_02",
                participantId: "1002",
                participantName: "Marcus",
                participantMediaHash: nil,
                participantCustomURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
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
