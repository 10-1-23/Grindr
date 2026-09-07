//
//  GrindrModels.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import Foundation

// MARK: - Core Profile Model
struct Profile: Identifiable, Codable, Hashable {
    let id: String
    var displayName: String?
    var aboutMe: String?
    var age: Int?
    var distance: Double? // distance in meters
    var isOnline: Bool?
    var lastActive: Int64?
    var mediaHash: String?
    var photos: [ProfilePhoto]?
    var tags: [String]?
    var ethnicity: String?
    var relationshipStatus: String?
    var bodyType: String?
    var height: Double? // in cm
    var weight: Double? // in kg
    var position: String?
    var lookingFor: [String]?
    var pronouns: String?
    var meetAt: [String]?
    var acceptsNsfw: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "profileId"
        case displayName
        case aboutMe
        case age
        case distance
        case isOnline
        case lastActive
        case mediaHash
        case photos
        case tags
        case ethnicity
        case relationshipStatus
        case bodyType
        case height
        case weight
        case position
        case lookingFor
        case pronouns
        case meetAt
        case acceptsNsfw
    }
    
    var formattedDistance: String {
        guard let d = distance else { return "Nearby" }
        let feet = d * 3.28084
        if feet < 1000 {
            return "\(Int(feet)) ft"
        }
        let miles = feet / 5280.0
        return String(format: "%.1f mi", miles)
    }
    
    var avatarURL: URL? {
        guard let hash = mediaHash, !hash.isEmpty else { return nil }
        return URL(string: "https://cdns.grindr.com/images/profile/1024x1024/\(hash)")
    }
}

// MARK: - Profile Photo
struct ProfilePhoto: Identifiable, Codable, Hashable {
    let id: String
    let mediaHash: String
    var caption: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "mediaId"
        case mediaHash
        case caption
    }
    
    var url: URL? {
        URL(string: "https://cdns.grindr.com/images/profile/1024x1024/\(mediaHash)")
    }
}

// MARK: - Cascade (Grid) Response
struct CascadeResponse: Codable {
    let entries: [CascadeItem]?
    let nextCursor: String?
    
    enum CodingKeys: String, CodingKey {
        case entries = "items"
        case nextCursor = "cursor"
    }
}

struct CascadeItem: Identifiable, Codable, Hashable {
    let id: String
    let profile: Profile?
    let distance: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "profileId"
        case profile
        case distance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let pid = try? container.decode(String.self, forKey: .id) {
            self.id = pid
        } else if let pidNum = try? container.decode(Int64.self, forKey: .id) {
            self.id = String(pidNum)
        } else {
            self.id = UUID().uuidString
        }
        self.distance = try? container.decode(Double.self, forKey: .distance)
        self.profile = try? Profile(from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(profile, forKey: .profile)
    }
}

// MARK: - Chat & Messaging Models
enum MessageType: String, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case expiringImage = "EXPIRING_IMAGE"
    case tap = "TAP"
    case audio = "AUDIO"
    case location = "LOCATION"
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let senderId: String
    let recipientId: String
    let timestamp: Int64
    var text: String?
    var type: MessageType
    var mediaUrl: String?
    var mediaId: Int64?
    var isExpiring: Bool
    var viewsRemaining: Int?
    var durationSeconds: Int?
    var isSavedLocally: Bool? = false
    
    enum CodingKeys: String, CodingKey {
        case id = "messageId"
        case senderId
        case recipientId
        case timestamp
        case text = "body"
        case type
        case mediaUrl = "url"
        case mediaId
        case isExpiring
        case viewsRemaining
        case durationSeconds
    }
    
    var resolvedMediaURL: URL? {
        guard let urlStr = mediaUrl, !urlStr.isEmpty else { return nil }
        return URL(string: urlStr)
    }
}

struct ChatConversation: Identifiable, Codable, Hashable {
    let id: String
    let participantId: String
    var participantName: String?
    var participantMediaHash: String?
    var lastMessageSnippet: String?
    var lastMessageTimestamp: Int64?
    var unreadCount: Int = 0
    var isMuted: Bool = false
    
    var avatarURL: URL? {
        guard let hash = participantMediaHash, !hash.isEmpty else { return nil }
        return URL(string: "https://cdns.grindr.com/images/profile/1024x1024/\(hash)")
    }
}

// MARK: - Album Models
struct GrindrAlbum: Identifiable, Codable, Hashable {
    let id: Int64
    var title: String?
    var photos: [AlbumContentItem]?
    var ownerProfileId: String?
    var isSharedWithMe: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case id = "albumId"
        case title
        case photos = "content"
        case ownerProfileId
    }
}

struct AlbumContentItem: Identifiable, Codable, Hashable {
    let id: Int64
    let mediaHash: String
    var caption: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "mediaId"
        case mediaHash
        case caption
    }
    
    var url: URL? {
        URL(string: "https://cdns.grindr.com/images/profile/1024x1024/\(mediaHash)")
    }
}

// MARK: - Tap Types
enum TapType: String, CaseIterable, Identifiable {
    case flame = "FLAME"
    case looking = "LOOKING"
    case friendly = "FRIENDLY"
    
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .flame: return "flame.fill"
        case .looking: return "eyes"
        case .friendly: return "hand.wave.fill"
        }
    }
    var title: String {
        switch self {
        case .flame: return "Hot"
        case .looking: return "Looking"
        case .friendly: return "Say Hi"
        }
    }
}
