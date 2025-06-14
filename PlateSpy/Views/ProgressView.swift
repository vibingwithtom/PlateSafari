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
            
            // Map access button
            MapAccessButton(game: game)
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
                
                Text("\(game.stateCount)/51")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(game.stateCount), total: 51.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("\(String(format: "%.1f", Double(game.stateCount) / 51.0 * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(51 - game.stateCount) remaining")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Collection Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(game.stateCount) states")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Top 5 states section
            if !game.stateProgress.isEmpty {
                TopFiveStatesView(game: game)
            }
        }
    }
}

/**
 * Top 5 states component for plate collection games
 * Shows clearly labeled ranking of states by plates collected
 */
struct TopFiveStatesView: View {
    let game: Game
    
    private var topStates: [(String, Int)] {
        let sorted = game.stateProgress.sorted { $0.value > $1.value }
        return Array(sorted.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Top \(min(topStates.count, 5)) States by Plates Collected")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 6) {
                ForEach(Array(topStates.enumerated()), id: \.element.0) { index, stateData in
                    let (state, count) = stateData
                    TopStateRow(
                        rank: index + 1,
                        state: state,
                        plateCount: count
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/**
 * Individual row showing state ranking in top 5 list
 */
struct TopStateRow: View {
    let rank: Int
    let state: String
    let plateCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 16, alignment: .center)
            
            // State name
            Text(state)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            // Plate count
            Text("\(plateCount) plate\(plateCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

/**
 * Simple button to access full map view
 */
struct MapAccessButton: View {
    let game: Game
    @State private var showingFullMap = false
    
    var body: some View {
        Button(action: { showingFullMap = true }) {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.blue)
                
                Text("View Collection Map")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingFullMap) {
            FullMapView(game: game)
        }
    }
}

#Preview {
    ProgressTrackingView()
        .environmentObject(GameManagerService())
}