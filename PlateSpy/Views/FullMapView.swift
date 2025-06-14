//
//  FullMapView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Full-screen map view for detailed progress visualization
 * Accessed via "View Full Map" button from progress cards
 */
struct FullMapView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Game info header
                    GameMapHeader(game: game)
                    
                    // Interactive map (without header)
                    USMapView(game: game, compactMode: false, showHeader: false)
                }
                .padding()
            }
            .navigationTitle("Collection Map")
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
 * Header section for the full map view
 */
struct GameMapHeader: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        VStack(spacing: 16) {
            // Game title and mode
            VStack(spacing: 8) {
                Text(gameManager.displayName(for: game))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(game.mode.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Quick stats
            HStack {
                StatBadge(
                    title: "States",
                    value: "\(game.stateCount)",
                    color: .blue
                )
                
                StatBadge(
                    title: "Plates",
                    value: "\(game.plateCount)",
                    color: .green
                )
                
                StatBadge(
                    title: "Score",
                    value: "\(game.totalScore)",
                    color: .purple
                )
                
                StatBadge(
                    title: "Progress",
                    value: String(format: "%.0f%%", completionPercentage),
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var completionPercentage: Double {
        switch game.mode {
        case .stateCollection:
            return Double(game.stateCount) / 51.0 * 100.0
        case .plateCollection:
            return min(Double(game.plateCount) / 200.0 * 100.0, 100.0)
        }
    }
}

/**
 * Individual statistic badge
 */
struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    FullMapView(game: Game(mode: .stateCollection, name: "State Challenge"))
        .environmentObject(GameManagerService())
}