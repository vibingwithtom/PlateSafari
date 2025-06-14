//
//  SettingsView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * App settings and preferences
 * Manages data loading, game preferences, and app information
 */
struct SettingsView: View {
    @EnvironmentObject var plateDataService: PlateDataService
    @EnvironmentObject var gameManager: GameManagerService
    
    @State private var showingDataRefresh = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Data management section
                Section {
                    DataStatusRow()
                    
                    Button("Refresh Data") {
                        plateDataService.loadPlateData()
                    }
                    .disabled(plateDataService.isLoading)
                    
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("License plate data contains \(plateDataService.plates.count) plates from all US states.")
                }
                
                // Game preferences section
                Section {
                    GamePreferencesView()
                } header: {
                    Text("Game Preferences")
                }
                
                // Statistics section
                Section {
                    StatisticsView()
                } header: {
                    Text("Statistics")
                }
                
                // About section
                Section {
                    Button("About PlateSpy") {
                        showingAbout = true
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        .foregroundColor(.blue)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                        .foregroundColor(.blue)
                        
                } header: {
                    Text("About")
                } footer: {
                    Text("PlateSpy v1.0 - License Plate Collection Game")
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

/**
 * Data loading status indicator
 */
struct DataStatusRow: View {
    @EnvironmentObject var plateDataService: PlateDataService
    
    var body: some View {
        HStack {
            Text("Data Status")
            
            Spacer()
            
            if plateDataService.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            } else if plateDataService.loadingError != nil {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Error")
                        .foregroundColor(.orange)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Loaded")
                        .foregroundColor(.green)
                }
            }
        }
    }
}

/**
 * Game preferences configuration
 */
struct GamePreferencesView: View {
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Default Game Mode")
                Spacer()
                Picker("", selection: .constant(gameManager.userPreferences.defaultGameMode)) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            if let lastState = gameManager.userPreferences.lastSelectedState {
                HStack {
                    Text("Last Selected State")
                    Spacer()
                    Text(lastState)
                        .foregroundColor(.secondary)
                }
            }
            
            if !gameManager.userPreferences.recentStates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent States")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        ForEach(gameManager.userPreferences.recentStates, id: \.self) { state in
                            Text(state)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

/**
 * App usage statistics
 */
struct StatisticsView: View {
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    
    var body: some View {
        Group {
            HStack {
                Text("Total Games")
                Spacer()
                Text("\(gameManager.games.count)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Available Plates")
                Spacer()
                Text("\(plateDataService.plates.count)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Available States")
                Spacer()
                Text("\(plateDataService.availableStates.count)")
                    .foregroundColor(.secondary)
            }
            
            let enhancedCount = plateDataService.plates.filter { $0.hasEnhancedMetadata }.count
            if enhancedCount > 0 {
                HStack {
                    Text("Enhanced Metadata")
                    Spacer()
                    Text("\(enhancedCount) plates")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/**
 * About app information sheet
 */
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and title
                    VStack(spacing: 16) {
                        Image(systemName: "car.rear.and.tire.marks")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 4) {
                            Text("PlateSpy")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("License Plate Collection Game")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Version 1.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About PlateSpy")
                            .font(.headline)
                        
                        Text("PlateSpy is the ultimate license plate spotting game! Collect plates from all 50 states and DC with two exciting game modes:")
                            .font(.body)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Image(systemName: "map")
                                    .foregroundColor(.blue)
                                Text("**State Collection**: The classic game - spot one plate from each state")
                            }
                            
                            HStack(alignment: .top) {
                                Image(systemName: "square.grid.3x3")
                                    .foregroundColor(.blue)
                                Text("**Plate Collection**: Collect as many unique plates as possible")
                            }
                        }
                        .font(.body)
                        
                        Text("With over 5,000 license plate designs from across the United States, there's always something new to discover!")
                            .font(.body)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "gamecontroller", title: "Multiple Games", description: "Run up to 5 collection games simultaneously")
                        FeatureRow(icon: "chart.bar", title: "Progress Tracking", description: "Visual maps and statistics for your collections")
                        FeatureRow(icon: "magnifyingglass", title: "Smart Search", description: "Find plates by category, rarity, and more")
                        FeatureRow(icon: "icloud", title: "Offline Ready", description: "Works without internet connection")
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/**
 * Individual feature row in about view
 */
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PlateDataService())
        .environmentObject(GameManagerService())
}