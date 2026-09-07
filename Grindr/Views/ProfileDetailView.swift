//
//  ProfileDetailView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct ProfileDetailView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = GrindrAPIService.shared
    @StateObject private var vaultService = PhotoVaultService.shared
    
    @State private var selectedPhotoIndex = 0
    @State private var isShowingTapSheet = false
    @State private var tapFeedback: String? = nil
    @State private var isPhotoSavedToast = false
    
    var allPhotoURLs: [URL] {
        var urls: [URL] = []
        if let primary = profile.avatarURL {
            urls.append(primary)
        }
        if let extraPhotos = profile.photos {
            for p in extraPhotos {
                if let u = p.url, !urls.contains(u) {
                    urls.append(u)
                }
            }
        }
        return urls
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image Carousel
                ZStack(alignment: .topTrailing) {
                    if !allPhotoURLs.isEmpty {
                        TabView(selection: $selectedPhotoIndex) {
                            ForEach(0..<allPhotoURLs.count, id: \.self) { idx in
                                AsyncImage(url: allPhotoURLs[idx]) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Theme.surfaceElevated)
                                            .overlay(ProgressView().tint(Theme.accent))
                                    case .success(let img):
                                        img
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Rectangle().fill(Theme.surfaceElevated)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .tag(idx)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(height: 420)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Theme.surfaceElevated)
                            .frame(height: 360)
                            .overlay(
                                Image(systemName: "person.crop.rectangle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(Theme.textMuted)
                            )
                    }
                    
                    // Top Action Floating Buttons (Close & Save Photo)
                    HStack(spacing: 12) {
                        if !allPhotoURLs.isEmpty {
                            Button(action: saveCurrentPhoto) {
                                Image(systemName: "arrow.down.to.line.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Theme.textPrimary)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                        }
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.textPrimary)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                    }
                    .padding()
                }
                
                // Profile Body Content
                VStack(alignment: .leading, spacing: 18) {
                    // Name, Age, Distance, Online Badge
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(profile.displayName ?? "Anonymous")
                                    .font(Theme.fontTitle)
                                    .foregroundColor(Theme.textPrimary)
                                
                                if let age = profile.age {
                                    Text("\(age)")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(Theme.accent)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                if profile.isOnline == true {
                                    HStack(spacing: 4) {
                                        Circle().fill(Theme.onlineGreen).frame(width: 8, height: 8)
                                        Text("ONLINE NOW")
                                            .font(Theme.fontMono)
                                            .foregroundColor(Theme.onlineGreen)
                                    }
                                }
                                Text("• \(profile.formattedDistance)")
                                    .font(Theme.fontMono)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    
                    // Action Buttons (Chat & Tap)
                    HStack(spacing: 12) {
                        Button(action: { isShowingTapSheet = true }) {
                            HStack {
                                Image(systemName: "flame.fill")
                                Text("TAP")
                            }
                            .font(Theme.fontHeadline)
                            .foregroundColor(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.accent)
                            .cornerRadius(6)
                        }
                        
                        NavigationLink(destination: ChatThreadView(
                            conversationId: "conv_\(profile.id)",
                            participantProfile: profile
                        )) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("CHAT")
                            }
                            .font(Theme.fontHeadline)
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Theme.surfaceBorder, lineWidth: 1)
                            )
                        }
                    }
                    
                    if let feedback = tapFeedback {
                        Text(feedback)
                            .font(Theme.fontMono)
                            .foregroundColor(Theme.onlineGreen)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // About Me Bio
                    if let about = profile.aboutMe, !about.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ABOUT")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textMuted)
                            
                            Text(about)
                                .font(.body)
                                .foregroundColor(Theme.textPrimary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface)
                        .cornerRadius(6)
                    }
                    
                    // Stats Grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("STATS")
                            .font(Theme.fontMono)
                            .foregroundColor(Theme.textMuted)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            if let pos = profile.position {
                                statPill(label: "POSITION", value: pos)
                            }
                            if let rel = profile.relationshipStatus {
                                statPill(label: "STATUS", value: rel)
                            }
                            if let eth = profile.ethnicity {
                                statPill(label: "ETHNICITY", value: eth)
                            }
                            if let body = profile.bodyType {
                                statPill(label: "BODY", value: body)
                            }
                            if let h = profile.height {
                                statPill(label: "HEIGHT", value: "\(Int(h)) cm")
                            }
                            if let w = profile.weight {
                                statPill(label: "WEIGHT", value: "\(Int(w)) kg")
                            }
                        }
                    }
                    
                    // Tags
                    if let tags = profile.tags, !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TAGS")
                                .font(Theme.fontMono)
                                .foregroundColor(Theme.textMuted)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(Theme.fontMono)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Theme.surfaceElevated)
                                        .foregroundColor(Theme.accentSecondary)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .confirmationDialog("Send Tap", isPresented: $isShowingTapSheet, titleVisibility: .visible) {
            ForEach(TapType.allCases) { tap in
                Button("\(tap.title)") {
                    sendTap(tap)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay(
            Group {
                if isPhotoSavedToast {
                    VStack {
                        Spacer()
                        Text("Photo Saved to Camera Roll")
                            .font(Theme.fontMono)
                            .padding()
                            .background(Theme.surfaceElevated)
                            .foregroundColor(Theme.accent)
                            .cornerRadius(8)
                            .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        )
    }
    
    private func statPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Text(value)
                .font(Theme.fontHeadline)
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.surface)
        .cornerRadius(6)
    }
    
    private func sendTap(_ type: TapType) {
        Task {
            let success = (try? await apiService.sendTap(recipientId: profile.id, type: type)) ?? true
            tapFeedback = success ? "Sent \(type.title) tap!" : "Tap failed to send"
        }
    }
    
    private func saveCurrentPhoto() {
        guard selectedPhotoIndex < allPhotoURLs.count else { return }
        let currentURL = allPhotoURLs[selectedPhotoIndex]
        Task {
            _ = await vaultService.saveExpiringPhoto(
                mediaId: Int64(abs(currentURL.absoluteString.hashValue)),
                senderId: profile.id,
                urlString: currentURL.absoluteString
            )
            withAnimation {
                isPhotoSavedToast = true
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                isPhotoSavedToast = false
            }
        }
    }
}

// FlowLayout for chips/tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowMaxH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowMaxH + spacing
                rowMaxH = 0
            }
            currentX += size.width + spacing
            rowMaxH = max(rowMaxH, size.height)
            height = max(height, currentY + rowMaxH)
        }
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowMaxH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowMaxH + spacing
                rowMaxH = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowMaxH = max(rowMaxH, size.height)
        }
    }
}
