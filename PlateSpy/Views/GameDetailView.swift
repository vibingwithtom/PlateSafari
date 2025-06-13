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
                    onLogPlate: { showingPlateSelector = true }
                )
            }
            .padding()
        }
        .navigationTitle(gameManager.displayName(for: game))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPlateSelector) {
            PlateSelectionSheet(game: game)
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
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(game.createdDate, style: .date)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Last Played")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(game.lastPlayedDate, style: .relative)
                        .font(.subheadline)
                }
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatItem(title: "Plates Collected", value: "\(stats.totalPlates)")
                    StatItem(title: "States", value: "\(stats.uniqueStates)")
                    StatItem(title: "Total Score", value: "\(stats.totalScore)")
                    StatItem(title: "Completion", value: String(format: "%.1f%%", stats.completionPercentage))
                }
                
                // Progress bar for state collection
                if game.mode == .stateCollection {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("State Progress")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(game.stateCount)/50")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: Double(game.stateCount), total: 50.0)
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
 * Recent plates section
 */
struct RecentPlatesSection: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Plates")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(game.collectedPlates.sorted { $0.collectedDate > $1.collectedDate }.prefix(5)), id: \.id) { plate in
                        RecentPlateCard(plate: plate)
                    }
                }
                .padding(.horizontal, 1) // Prevents clipping shadows
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * Individual recent plate card
 */
struct RecentPlateCard: View {
    let plate: CollectedPlate
    
    var body: some View {
        VStack(spacing: 8) {
            // Placeholder for plate image
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .aspectRatio(2, contentMode: .fit)
                .frame(width: 80)
                .overlay(
                    VStack {
                        Text(plate.state)
                            .font(.caption2)
                            .fontWeight(.bold)
                        
                        Image(systemName: "car.rear")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                )
            
            Text(plate.plateTitle)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
    }
}

/**
 * Game action buttons section
 */
struct GameActionsSection: View {
    let onLogPlate: () -> Void
    
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
                Button(action: {}) {
                    Label("View Map", systemImage: "map")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Label("All Plates", systemImage: "list.bullet")
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
    }
}

/**
 * Placeholder for plate selection sheet
 */
struct PlateSelectionSheet: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Plate Selection")
                    .font(.title)
                
                Text("This will be the plate logging interface")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Log Plate")
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

#Preview {
    NavigationView {
        GameDetailView(game: Game(mode: .stateCollection, name: "My Collection"))
    }
    .environmentObject(GameManagerService())
    .environmentObject(PlateDataService())
}