//
//  InboxView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct InboxView: View {
    @StateObject private var apiService = GrindrAPIService.shared
    @State private var conversations: [ChatConversation] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SECURE INBOX")
                                .font(Theme.fontHeadline)
                                .foregroundColor(Theme.textPrimary)
                            Text("\(conversations.count) ACTIVE CHATS")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        
                        Button(action: { Task { await refreshInbox() } }) {
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
                    
                    if isLoading && conversations.isEmpty {
                        Spacer()
                        ProgressView().tint(Theme.accent)
                        Spacer()
                    } else if conversations.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.textMuted)
                            Text("No Active Conversations")
                                .font(Theme.fontHeadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(conversations) { conv in
                                NavigationLink(destination: ChatThreadView(
                                    conversationId: conv.id,
                                    participantProfile: Profile(
                                        id: conv.participantId,
                                        displayName: conv.participantName,
                                        aboutMe: nil,
                                        age: nil,
                                        distance: nil,
                                        isOnline: true,
                                        lastActive: conv.lastMessageTimestamp,
                                        mediaHash: conv.participantMediaHash
                                    )
                                )) {
                                    conversationRow(for: conv)
                                }
                                .listRowBackground(Theme.surface)
                                .listRowSeparatorTint(Theme.surfaceBorder)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .refreshable {
                            await refreshInbox()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if conversations.isEmpty {
                Task { await refreshInbox() }
            }
        }
    }
    
    private func conversationRow(for conv: ChatConversation) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .topTrailing) {
                if let avatar = conv.avatarURL {
                    AsyncImage(url: avatar) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                        } else {
                            Circle().fill(Theme.surfaceElevated)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Theme.surfaceElevated)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Theme.textMuted)
                        )
                }
                
                if conv.unreadCount > 0 {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 12, height: 12)
                }
            }
            
            // Conversation info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conv.participantName ?? "Anonymous")
                        .font(Theme.fontHeadline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    if let ts = conv.lastMessageTimestamp {
                        Text(formatTimestamp(ts))
                            .font(Theme.fontMono)
                            .foregroundColor(Theme.textMuted)
                    }
                }
                
                Text(conv.lastMessageSnippet ?? "No messages yet")
                    .font(.subheadline)
                    .foregroundColor(conv.unreadCount > 0 ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTimestamp(_ ms: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func refreshInbox() async {
        isLoading = true
        if let fetched = try? await apiService.fetchInbox() {
            conversations = fetched
        }
        isLoading = false
    }
}
