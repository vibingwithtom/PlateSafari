//
//  MainTabView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Main navigation structure for the PlateSpy app
 * Provides access to all major app features through tab-based navigation
 */
struct MainTabView: View {
    @EnvironmentObject var plateDataService: PlateDataService
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        TabView {
            // Games tab - Primary entry point for users
            GamesListView()
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("Games")
                }
            
            // Browse plates tab - Explore the plate database
            PlatesBrowserView()
                .tabItem {
                    Image(systemName: "square.grid.3x3")
                    Text("Browse")
                }
            
            // Progress tab - View collection progress and maps
            ProgressTrackingView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Progress")
                }
            
            // Settings tab - App preferences and data management
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue) // Consistent color theme throughout app
    }
}