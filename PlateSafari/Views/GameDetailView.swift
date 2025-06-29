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
    
    private var gameName: String {
        gameManager.displayName(for: game)
    }
    
    private var titleDisplayMode: NavigationBarItem.TitleDisplayMode {
        // Use inline mode for long titles to prevent truncation
        return gameName.count > 25 ? .inline : .large
    }
    
    private var shouldShowCustomHeader: Bool {
        // Show custom header for very long titles that might still truncate in inline mode
        return gameName.count > 35
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Custom header for very long game names
                if shouldShowCustomHeader {
                    GameNameHeader(gameName: gameName)
                }
                
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
        .navigationTitle(shouldShowCustomHeader ? "Game Details" : gameName)
        .navigationBarTitleDisplayMode(titleDisplayMode)
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
                        StatItem(title: "Plates Collected", value: "\(stats.totalPlates)", color: .green)
                        StatItem(title: "States", value: "\(stats.uniqueStates)", color: .orange)
                        StatItem(title: "Total Score", value: "\(stats.totalScore)", color: .purple)
                        StatItem(title: "Completion", value: String(format: "%.1f%%", stats.completionPercentage), color: .blue)
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
 * Individual statistic item (matches OverallStatItem design with uniform height)
 */
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 80) // Fixed minimum height for uniform appearance
        .padding(.vertical, 12)
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
 * Individual recent plate card with remove and view functionality
 */
struct RecentPlateCard: View {
    let plate: CollectedPlate
    let onRemove: () -> Void
    @State private var showingPlateDetail = false
    
    private var plateMetadata: PlateMetadata {
        PlateMetadata(
            state: plate.state,
            plateTitle: plate.plateTitle,
            plateImage: plate.plateImage,
            colorBackground: nil,
            textColor: nil,
            visualElements: nil,
            category: plate.category?.rawValue,
            rarity: plate.rarity?.rawValue,
            layoutStyle: nil,
            confidenceScore: nil,
            notes: nil,
            source: plate.source
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Plate image with tap to view and remove button
            Button(action: { showingPlateDetail = true }) {
                AsyncPlateImageView(
                    plate: plateMetadata,
                    cornerRadius: 6
                )
                .aspectRatio(2, contentMode: .fit)
                .frame(width: 80)
                .overlay(
                    // Remove button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onRemove) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                    }
                    .padding(4)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Plate title (also tappable)
            Button(action: { showingPlateDetail = true }) {
                Text(plate.plateTitle)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingPlateDetail) {
            PlateDetailView(plate: plateMetadata, game: nil)
        }
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

/**
 * Custom header for displaying very long game names
 */
struct GameNameHeader: View {
    let gameName: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(gameName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
            
            Divider()
        }
        .padding(.top, 8)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        GameDetailView(game: Game(mode: .stateCollection, name: "My Collection"))
    }
    .environmentObject(GameManagerService())
    .environmentObject(PlateDataService())
}