//
//  ContentView.swift
//  GrindrX - Sovereign Client
//  Created for Mrdo1o Mac / LSJ Systems Consulting
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .grid
    
    enum TabItem: Hashable {
        case grid
        case inbox
        case vault
        case albums
        case settings
    }
    
    init() {
        // Configure dark navigation & tab bars
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "070a12"))
        
        // Unselected item tint
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "64748b"))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "64748b")),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Selected item tint
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "ffd200"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "ffd200")),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CascadeGridView()
                .tabItem {
                    Label("Cascade", systemImage: "square.grid.3x3.fill")
                }
                .tag(TabItem.grid)
            
            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(TabItem.inbox)
            
            PhotoVaultView()
                .tabItem {
                    Label("Vault", systemImage: "lock.shield.fill")
                }
                .tag(TabItem.vault)
            
            SharedAlbumsView()
                .tabItem {
                    Label("Albums", systemImage: "rectangle.stack.fill")
                }
                .tag(TabItem.albums)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(TabItem.settings)
        }
        .accentColor(Theme.accent)
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
