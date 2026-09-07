//
//  ProfileCardView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct ProfileCardView: View {
    let profile: Profile
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Profile Photo or Slate Placeholder
            Group {
                if let url = profile.avatarURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Theme.surfaceElevated)
                                .overlay(ProgressView().tint(Theme.accent))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallbackPlaceholder
                        @unknown default:
                            fallbackPlaceholder
                        }
                    }
                } else {
                    fallbackPlaceholder
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fill)
            .clipped()
            
            // Bottom Gradient Overlay for readability
            LinearGradient(
                colors: [Color.black.opacity(0.85), Color.black.opacity(0.0)],
                startPoint: .bottom,
                endPoint: .center
            )
            
            // Online Indicator Dot (Top Left)
            if profile.isOnline == true {
                VStack {
                    HStack {
                        Circle()
                            .fill(Theme.onlineGreen)
                            .frame(width: 9, height: 9)
                            .shadow(color: Theme.onlineGreen.opacity(0.8), radius: 4, x: 0, y: 0)
                            .padding(6)
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            // Profile Name & Distance Info (Bottom)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(profile.displayName ?? "Anonymous")
                        .font(Theme.fontHeadline)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    if let age = profile.age {
                        Text("\(age)")
                            .font(Theme.fontMono)
                            .foregroundColor(Theme.accent)
                    }
                }
                
                Text(profile.formattedDistance)
                    .font(Theme.fontMono)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(6)
        }
        .background(Theme.surface)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.surfaceBorder, lineWidth: 0.8)
        )
    }
    
    private var fallbackPlaceholder: some View {
        Rectangle()
            .fill(Theme.surfaceElevated)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.textMuted)
            )
    }
}
