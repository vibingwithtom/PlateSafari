//
//  MainTabView.swift
//  PlateSafari
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Main navigation structure for the Plate Safari app
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
            
            // Plate Gallery tab - Explore the plate database
            PlatesBrowserView()
                .tabItem {
                    Image(systemName: "square.grid.3x3")
                    Text("Plate Gallery")
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