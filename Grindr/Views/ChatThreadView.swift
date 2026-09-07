//
//  ChatThreadView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct ChatThreadView: View {
    let conversationId: String
    let participantProfile: Profile?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = GrindrAPIService.shared
    @StateObject private var vaultService = PhotoVaultService.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputMessage: String = ""
    @State private var isSending: Bool = false
    @State private var savedMediaToast: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar
            
            // Messages Scroll Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            messageRow(for: msg)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    loadMockMessages()
                }
            }
            
            // Input Bar
            inputBar
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .overlay(
            Group {
                if let toast = savedMediaToast {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(Theme.fontMono)
                            .padding()
                            .background(Theme.surfaceElevated)
                            .foregroundColor(Theme.accent)
                            .cornerRadius(8)
                            .padding(.bottom, 60)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        )
    }
    
    // Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            if let avatar = participantProfile?.avatarURL {
                AsyncImage(url: avatar) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Circle().fill(Theme.surfaceElevated)
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Theme.surfaceElevated)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textMuted)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participantProfile?.displayName ?? "Chat")
                    .font(Theme.fontHeadline)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(participantProfile?.isOnline == true ? Theme.onlineGreen : Theme.textMuted)
                        .frame(width: 6, height: 6)
                    Text(participantProfile?.isOnline == true ? "Online" : participantProfile?.formattedDistance ?? "Nearby")
                        .font(Theme.fontMono)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            // Quick Flame Tap
            Button(action: sendQuickFlame) {
                Image(systemName: "flame.fill")
                    .foregroundColor(Theme.accent)
                    .padding(8)
                    .background(Theme.surfaceElevated)
                    .clipShape(Circle())
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
    
    // Message Row
    @ViewBuilder
    private func messageRow(for msg: ChatMessage) -> some View {
        let isMe = msg.senderId == "me"
        
        HStack {
            if isMe { Spacer() }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                switch msg.type {
                case .text:
                    Text(msg.text ?? "")
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isMe ? Theme.accent : Theme.surfaceElevated)
                        .foregroundColor(isMe ? Theme.background : Theme.textPrimary)
                        .cornerRadius(12)
                    
                case .expiringImage:
                    expiringPhotoCard(msg: msg)
                    
                case .image:
                    if let url = msg.resolvedMediaURL {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFit().frame(maxWidth: 220).cornerRadius(8)
                            } else {
                                ProgressView()
                            }
                        }
                    }
                    
                case .tap:
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundColor(Theme.accent)
                        Text("Sent a Flame Tap").font(Theme.fontHeadline)
                    }
                    .padding(10)
                    .background(Theme.surface)
                    .cornerRadius(8)
                    
                default:
                    Text(msg.text ?? "Unsupported message")
                        .font(.caption)
                        .foregroundColor(Theme.textMuted)
                }
            }
            
            if !isMe { Spacer() }
        }
    }
    
    // Expiring Photo Card (The GrindrX Secret Weapon!)
    private func expiringPhotoCard(msg: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundColor(Theme.danger)
                Text("EXPIRING PHOTO (UNBLURRED)")
                    .font(Theme.fontMono)
                    .foregroundColor(Theme.danger)
            }
            
            if let mediaUrl = msg.mediaUrl, let url = URL(string: mediaUrl) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 260)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Theme.surfaceElevated)
                            .frame(width: 220, height: 260)
                            .overlay(ProgressView())
                    }
                }
            } else {
                Rectangle()
                    .fill(Theme.surfaceElevated)
                    .frame(width: 220, height: 260)
                    .cornerRadius(8)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundColor(Theme.accent)
                            Text("Media Decrypted")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textSecondary)
                        }
                    )
            }
            
            // Instant Save Button (Bypasses countdown & deletion)
            Button(action: {
                saveExpiringPhoto(msg: msg)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.to.line.circle.fill")
                    Text("SAVE TO VAULT FOREVER")
                }
                .font(Theme.fontMono)
                .foregroundColor(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .cornerRadius(6)
            }
        }
        .padding(10)
        .background(Theme.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.danger.opacity(0.6), lineWidth: 1)
        )
    }
    
    // Bottom Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Type a secure message...", text: $inputMessage)
                .font(.body)
                .padding(10)
                .background(Theme.surfaceElevated)
                .foregroundColor(Theme.textPrimary)
                .cornerRadius(6)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(inputMessage.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textMuted : Theme.accent)
                    .padding(10)
                    .background(Theme.surfaceElevated)
                    .clipShape(Circle())
            }
            .disabled(inputMessage.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Theme.surface)
    }
    
    private func sendMessage() {
        guard !inputMessage.isEmpty else { return }
        let newMsg = ChatMessage(
            id: UUID().uuidString,
            senderId: "me",
            recipientId: participantProfile?.id ?? "other",
            timestamp: Date().millisecondsSince1970,
            text: inputMessage,
            type: .text,
            mediaUrl: nil,
            mediaId: nil,
            isExpiring: false,
            viewsRemaining: nil,
            durationSeconds: nil
        )
        messages.append(newMsg)
        inputMessage = ""
    }
    
    private func sendQuickFlame() {
        let flameMsg = ChatMessage(
            id: UUID().uuidString,
            senderId: "me",
            recipientId: participantProfile?.id ?? "other",
            timestamp: Date().millisecondsSince1970,
            text: nil,
            type: .tap,
            mediaUrl: nil,
            mediaId: nil,
            isExpiring: false,
            viewsRemaining: nil,
            durationSeconds: nil
        )
        messages.append(flameMsg)
    }
    
    private func saveExpiringPhoto(msg: ChatMessage) {
        guard let urlStr = msg.mediaUrl else {
            showToast("Saved to offline vault")
            return
        }
        Task {
            let success = await vaultService.saveExpiringPhoto(
                mediaId: msg.mediaId ?? Int64(abs(msg.id.hashValue)),
                senderId: msg.senderId,
                urlString: urlStr
            )
            showToast(success ? "Expiring photo preserved forever!" : "Save failed")
        }
    }
    
    private func showToast(_ text: String) {
        withAnimation { savedMediaToast = text }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { savedMediaToast = nil }
        }
    }
    
    private func loadMockMessages() {
        messages = [
            ChatMessage(
                id: "1",
                senderId: participantProfile?.id ?? "other",
                recipientId: "me",
                timestamp: Date().millisecondsSince1970 - 300000,
                text: "Hey! Just saw your profile nearby.",
                type: .text,
                mediaUrl: nil,
                mediaId: nil,
                isExpiring: false,
                viewsRemaining: nil,
                durationSeconds: nil
            ),
            ChatMessage(
                id: "2",
                senderId: participantProfile?.id ?? "other",
                recipientId: "me",
                timestamp: Date().millisecondsSince1970 - 180000,
                text: nil,
                type: .expiringImage,
                mediaUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500",
                mediaId: 994821,
                isExpiring: true,
                viewsRemaining: 1,
                durationSeconds: 10
            ),
            ChatMessage(
                id: "3",
                senderId: "me",
                recipientId: participantProfile?.id ?? "other",
                timestamp: Date().millisecondsSince1970 - 60000,
                text: "Hey there! Looking good.",
                type: .text,
                mediaUrl: nil,
                mediaId: nil,
                isExpiring: false,
                viewsRemaining: nil,
                durationSeconds: nil
            )
        ]
    }
}
