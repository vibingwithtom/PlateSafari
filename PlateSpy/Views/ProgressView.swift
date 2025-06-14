//
//  ProgressView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Progress visualization and statistics view
 * Shows collection progress across all games with maps and charts
 */
struct ProgressTrackingView: View {
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if gameManager.games.isEmpty {
                        EmptyProgressView()
                    } else {
                        // Overall statistics
                        OverallStatsCard()
                        
                        // Game progress cards
                        ForEach(gameManager.games) { game in
                            GameProgressCard(game: game)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

/**
 * Empty state when no games exist
 */
struct EmptyProgressView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Progress to Show")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Create a game and start collecting plates to see your progress here!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/**
 * Overall statistics across all games
 */
struct OverallStatsCard: View {
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Statistics")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                OverallStatItem(
                    title: "Total Games",
                    value: "\(gameManager.games.count)",
                    color: .blue
                )
                
                OverallStatItem(
                    title: "Total Plates",
                    value: "\(totalPlates)",
                    color: .green
                )
                
                OverallStatItem(
                    title: "Unique States",
                    value: "\(uniqueStates)",
                    color: .orange
                )
                
                OverallStatItem(
                    title: "Total Score",
                    value: "\(totalScore)",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var totalPlates: Int {
        gameManager.games.reduce(0) { $0 + $1.plateCount }
    }
    
    private var uniqueStates: Int {
        let allStates = Set(gameManager.games.flatMap { game in
            game.collectedPlates.map { $0.state }
        })
        return allStates.count
    }
    
    private var totalScore: Int {
        gameManager.games.reduce(0) { $0 + $1.totalScore }
    }
}

/**
 * Individual overall statistic item
 */
struct OverallStatItem: View {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

/**
 * Progress card for individual game
 */
struct GameProgressCard: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(gameManager.displayName(for: game))
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(game.mode.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(game.plateCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("plates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress visualization
            if game.mode == .stateCollection {
                StateCollectionProgress(game: game)
            } else {
                PlateCollectionProgress(game: game)
            }
            
            // Map placeholder
            MapPlaceholder(game: game)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * Progress view for state collection mode
 */
struct StateCollectionProgress: View {
    let game: Game
    
    var body: some View {
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
            
            HStack {
                Text("\(String(format: "%.1f", Double(game.stateCount) / 50.0 * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(50 - game.stateCount) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/**
 * Progress view for plate collection mode
 */
struct PlateCollectionProgress: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Collection Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(game.stateCount) states")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Top states by plate count
            let topStates = game.stateProgress.sorted { $0.value > $1.value }.prefix(5)
            
            VStack(spacing: 4) {
                ForEach(Array(topStates), id: \.key) { state, count in
                    HStack {
                        Text(state)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/**
 * Placeholder for map visualization
 */
struct MapPlaceholder: View {
    let game: Game
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Collection Map")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("View Full Map") {
                    // TODO: Navigate to full map view
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "map")
                            .font(.title)
                            .foregroundColor(.gray)
                        
                        Text("Interactive Map")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
}

#Preview {
    ProgressTrackingView()
        .environmentObject(GameManagerService())
}