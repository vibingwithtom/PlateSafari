//
//  GamesListView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Main games management interface
 * Shows up to 5 active games with creation and deletion capabilities
 */
struct GamesListView: View {
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    
    @State private var showingCreateGame = false
    @State private var gameToDelete: Game?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if gameManager.games.isEmpty {
                    // Empty state with helpful guidance
                    EmptyGamesView {
                        showingCreateGame = true
                    }
                } else {
                    // Games list
                    List {
                        ForEach(gameManager.games) { game in
                            NavigationLink(destination: GameDetailView(game: game)) {
                                GameRowView(game: game)
                            }
                        }
                        .onDelete(perform: deleteGames)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("My Games")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGame = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(!gameManager.canCreateNewGame)
                }
            }
            .sheet(isPresented: $showingCreateGame) {
                CreateGameSheet()
            }
            .alert("Delete Game", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let game = gameToDelete {
                        _ = gameManager.deleteGame(id: game.id)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let game = gameToDelete {
                    Text("Are you sure you want to delete \"\(gameManager.displayName(for: game))\"? This action cannot be undone.")
                }
            }
        }
    }
    
    /**
     * Handle swipe-to-delete on games list
     */
    private func deleteGames(offsets: IndexSet) {
        for index in offsets {
            gameToDelete = gameManager.games[index]
            showingDeleteConfirmation = true
        }
    }
}

/**
 * Individual game row showing key information
 * Displays mode, creation date, and collection progress
 */
struct GameRowView: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Game mode icon
                Image(systemName: game.mode == .stateCollection ? "map" : "square.grid.3x3")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Game name or auto-generated title
                    Text(gameManager.displayName(for: game))
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Game mode description
                    Text(game.mode.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(game.plateCount) plates")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if game.mode == .stateCollection {
                        Text("\(game.stateCount)/51 states")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(game.stateCount) states")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Progress bar for state collection mode
            if game.mode == .stateCollection {
                ProgressView(value: Double(game.stateCount), total: 51.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 0.7) // Make progress bar thinner
            }
            
            // Score for enhanced metadata (if available)
            if game.totalScore > game.plateCount {
                HStack {
                    Spacer()
                    Text("\(game.totalScore) pts")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/**
 * Empty state view when no games exist
 * Provides clear guidance on how to get started
 */
struct EmptyGamesView: View {
    let onCreateGame: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Games Yet")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Create your first license plate collection game to get started!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: onCreateGame) {
                Label("Create Game", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}


#Preview {
    GamesListView()
        .environmentObject(GameManagerService())
        .environmentObject(PlateDataService())
}
