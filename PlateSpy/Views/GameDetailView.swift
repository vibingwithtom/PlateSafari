//
//  GameDetailView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Detailed view for an individual game
 * Shows progress, collected plates, and provides plate logging interface
 */
struct GameDetailView: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    
    @State private var showingPlateSelector = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Game overview card
                GameOverviewCard(game: game)
                
                // Quick stats
                GameStatsCard(game: game)
                
                // Recent plates section
                if !game.collectedPlates.isEmpty {
                    RecentPlatesSection(game: game)
                }
                
                // Action buttons
                GameActionsSection(
                    game: game,
                    onLogPlate: { showingPlateSelector = true }
                )
            }
            .padding()
        }
        .navigationTitle(gameManager.displayName(for: game))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPlateSelector) {
            StreamlinedPlateLoggingView(game: game)
        }
    }
}

/**
 * Game overview information card
 */
struct GameOverviewCard: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: game.mode == .stateCollection ? "map" : "square.grid.3x3")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(game.mode.displayName)
                        .font(.headline)
                    
                    Text(game.mode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * Game statistics card
 */
struct GameStatsCard: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let stats = gameManager.gameStatistics(for: game.id) {
                GeometryReader { geometry in
                    LazyVGrid(columns: ResponsiveLayout.responsiveColumns(geometry: geometry, portraitColumns: 2, landscapeColumns: 4), spacing: 16) {
                        StatItem(title: "Plates Collected", value: "\(stats.totalPlates)")
                        StatItem(title: "States", value: "\(stats.uniqueStates)")
                        StatItem(title: "Total Score", value: "\(stats.totalScore)")
                        StatItem(title: "Completion", value: String(format: "%.1f%%", stats.completionPercentage))
                    }
                }
                .frame(height: 120) // Fixed height for the grid
                
                // Progress bar for state collection
                if game.mode == .stateCollection {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("State Progress")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(game.stateCount)/51")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: Double(game.stateCount), total: 51.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * Individual statistic item
 */
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

/**
 * Recent plates section with undo functionality
 */
struct RecentPlatesSection: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    @State private var plateToRemove: CollectedPlate?
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Plates")
                    .font(.headline)
                
                Spacer()
                
                Text("Tap to remove")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(game.collectedPlates.sorted { $0.collectedDate > $1.collectedDate }.prefix(5)), id: \.id) { plate in
                        RecentPlateCard(
                            plate: plate,
                            onRemove: {
                                plateToRemove = plate
                                showingRemoveConfirmation = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 1) // Prevents clipping shadows
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .alert("Remove Plate", isPresented: $showingRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                if let plate = plateToRemove {
                    _ = gameManager.removePlate(
                        gameId: game.id,
                        state: plate.state,
                        plateTitle: plate.plateTitle
                    )
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let plate = plateToRemove {
                Text("Remove \"\(plate.plateTitle)\" from \(plate.state)? This action cannot be undone.")
            }
        }
    }
}

/**
 * Individual recent plate card with remove functionality
 */
struct RecentPlateCard: View {
    let plate: CollectedPlate
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onRemove) {
            VStack(spacing: 8) {
                // Create temporary PlateMetadata for image loading
                AsyncPlateImageView(
                    plate: PlateMetadata(
                        state: plate.state,
                        plateTitle: plate.plateTitle,
                        plateImage: plate.plateImage
                    ),
                    cornerRadius: 6
                )
                .aspectRatio(2, contentMode: .fit)
                .frame(width: 80)
                .overlay(
                    // Remove indicator
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(4)
                )
                
                Text(plate.plateTitle)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * Game action buttons section
 */
struct GameActionsSection: View {
    let game: Game
    let onLogPlate: () -> Void
    @State private var showingMapView = false
    @State private var showingAllPlates = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onLogPlate) {
                Label("Log New Plate", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                Button(action: { showingMapView = true }) {
                    Label("View Map", systemImage: "map")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Button(action: { showingAllPlates = true }) {
                    Label("Collected Plates", systemImage: "list.bullet")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingMapView) {
            FullMapView(game: game)
        }
        .sheet(isPresented: $showingAllPlates) {
            AllCollectedPlatesView(game: game)
        }
    }
}


#Preview {
    NavigationStack {
        GameDetailView(game: Game(mode: .stateCollection, name: "My Collection"))
    }
    .environmentObject(GameManagerService())
    .environmentObject(PlateDataService())
}