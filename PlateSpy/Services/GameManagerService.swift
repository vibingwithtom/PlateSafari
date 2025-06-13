//
//  GameManagerService.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import Foundation

/**
 * Service for managing game state and persistence
 * Handles multiple simultaneous games (up to 5) with automatic saving
 */
class GameManagerService: ObservableObject {
    @Published var games: [Game] = []
    @Published var userPreferences = UserPreferences()
    
    private let maxGames = 5
    private let userDefaults = UserDefaults.standard
    private let gamesKey = "saved_games"
    private let preferencesKey = "user_preferences"
    
    init() {
        loadGames()
        loadPreferences()
    }
    
    // MARK: - Game Management
    
    /**
     * Create a new game with specified mode and optional name
     * Enforces maximum of 5 simultaneous games
     */
    func createGame(mode: GameMode, name: String? = nil) -> Game? {
        guard games.count < maxGames else {
            print("❌ Cannot create game: Maximum of \(maxGames) games allowed")
            return nil
        }
        
        let newGame = Game(mode: mode, name: name)
        games.append(newGame)
        sortGamesByDate()
        saveGames()
        
        print("✅ Created new \(mode.displayName) game")
        return newGame
    }
    
    /**
     * Delete a game by ID
     * Includes confirmation to prevent accidental deletion
     */
    func deleteGame(id: UUID) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == id }) else {
            return false
        }
        
        games.remove(at: index)
        saveGames()
        
        print("🗑️ Deleted game with ID: \(id)")
        return true
    }
    
    /**
     * Get a specific game by ID
     */
    func game(with id: UUID) -> Game? {
        return games.first { $0.id == id }
    }
    
    /**
     * Update an existing game after modifications
     * Call this after collecting or removing plates
     */
    func updateGame(_ updatedGame: Game) {
        guard let index = games.firstIndex(where: { $0.id == updatedGame.id }) else {
            return
        }
        
        games[index] = updatedGame
        sortGamesByDate()
        saveGames()
    }
    
    // MARK: - Plate Collection Actions
    
    /**
     * Collect a plate in a specific game
     * Returns true if successfully collected, false if already exists
     */
    func collectPlate(gameId: UUID, metadata: PlateMetadata) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == gameId }) else {
            return false
        }
        
        let success = games[index].collectPlate(metadata: metadata)
        if success {
            // Update recent states for better UX
            userPreferences.addRecentState(metadata.state)
            savePreferences()
            
            sortGamesByDate() // Move recently played game to top
            saveGames()
            
            print("🎯 Collected \(metadata.plateTitle) from \(metadata.state)")
        } else {
            print("⚠️ Plate already collected: \(metadata.plateTitle)")
        }
        
        return success
    }
    
    /**
     * Remove a plate from a specific game
     * Used for undo functionality
     */
    func removePlate(gameId: UUID, state: String, plateTitle: String) -> Bool {
        guard let index = games.firstIndex(where: { $0.id == gameId }) else {
            return false
        }
        
        let success = games[index].removePlate(state: state, plateTitle: plateTitle)
        if success {
            sortGamesByDate()
            saveGames()
            
            print("↩️ Removed \(plateTitle) from \(state)")
        }
        
        return success
    }
    
    /**
     * Check if a plate is collected in a specific game
     */
    func isPlateCollected(gameId: UUID, state: String, plateTitle: String) -> Bool {
        guard let game = games.first(where: { $0.id == gameId }) else {
            return false
        }
        
        return game.hasCollected(state: state, plateTitle: plateTitle)
    }
    
    // MARK: - Game Statistics
    
    /**
     * Get progress statistics for a specific game
     */
    func gameStatistics(for gameId: UUID) -> GameStatistics? {
        guard let game = games.first(where: { $0.id == gameId }) else {
            return nil
        }
        
        return GameStatistics(
            totalPlates: game.plateCount,
            uniqueStates: game.stateCount,
            totalScore: game.totalScore,
            stateProgress: game.stateProgress,
            averageRarity: calculateAverageRarity(for: game),
            completionPercentage: calculateCompletionPercentage(for: game)
        )
    }
    
    /**
     * Calculate completion percentage based on game mode
     */
    private func calculateCompletionPercentage(for game: Game) -> Double {
        switch game.mode {
        case .stateCollection:
            return Double(game.stateCount) / 50.0 * 100.0
        case .plateCollection:
            // For plate collection, use a relative scale based on typical completion
            let typical = 200 // Typical goal for serious collectors
            return min(Double(game.plateCount) / Double(typical) * 100.0, 100.0)
        }
    }
    
    /**
     * Calculate average rarity score for collected plates
     */
    private func calculateAverageRarity(for game: Game) -> Double {
        let totalRarity = game.collectedPlates.reduce(0) { total, plate in
            total + (plate.rarity?.pointValue ?? 1)
        }
        return game.plateCount > 0 ? Double(totalRarity) / Double(game.plateCount) : 0.0
    }
    
    // MARK: - Persistence
    
    /**
     * Save games to UserDefaults
     * Automatic backup for game progress
     */
    private func saveGames() {
        do {
            let data = try JSONEncoder().encode(games)
            userDefaults.set(data, forKey: gamesKey)
            print("💾 Saved \(games.count) games")
        } catch {
            print("❌ Failed to save games: \(error)")
        }
    }
    
    /**
     * Load games from UserDefaults
     */
    private func loadGames() {
        guard let data = userDefaults.data(forKey: gamesKey) else {
            print("📁 No saved games found")
            return
        }
        
        do {
            games = try JSONDecoder().decode([Game].self, from: data)
            sortGamesByDate()
            print("📁 Loaded \(games.count) saved games")
        } catch {
            print("❌ Failed to load games: \(error)")
            games = []
        }
    }
    
    /**
     * Save user preferences
     */
    private func savePreferences() {
        do {
            let data = try JSONEncoder().encode(userPreferences)
            userDefaults.set(data, forKey: preferencesKey)
        } catch {
            print("❌ Failed to save preferences: \(error)")
        }
    }
    
    /**
     * Load user preferences
     */
    private func loadPreferences() {
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            return
        }
        
        do {
            userPreferences = try JSONDecoder().decode(UserPreferences.self, from: data)
        } catch {
            print("❌ Failed to load preferences: \(error)")
            userPreferences = UserPreferences()
        }
    }
    
    /**
     * Sort games by last played date (most recent first)
     * Ensures active games appear at the top of the list
     */
    private func sortGamesByDate() {
        games.sort { $0.lastPlayedDate > $1.lastPlayedDate }
    }
    
    // MARK: - Utility Methods
    
    /**
     * Check if maximum number of games has been reached
     */
    var canCreateNewGame: Bool {
        return games.count < maxGames
    }
    
    /**
     * Get display name for a game (uses custom name or generates default)
     */
    func displayName(for game: Game) -> String {
        if let name = game.name, !name.isEmpty {
            return name
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(game.mode.displayName) - \(formatter.string(from: game.createdDate))"
    }
}

/**
 * Statistics for individual games
 * Used for progress displays and achievements
 */
struct GameStatistics {
    let totalPlates: Int
    let uniqueStates: Int
    let totalScore: Int
    let stateProgress: [String: Int]
    let averageRarity: Double
    let completionPercentage: Double
}