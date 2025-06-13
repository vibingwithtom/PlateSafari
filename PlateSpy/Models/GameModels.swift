//
//  GameModels.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import Foundation

/**
 * Core game model supporting two collection modes
 * State Collection: Traditional "one plate per state" (50 total)
 * Plate Collection: Collect as many unique plates as possible
 */
struct Game: Codable, Identifiable {
    let id: UUID
    let name: String?
    let mode: GameMode
    let createdDate: Date
    var lastPlayedDate: Date
    var collectedPlates: Set<CollectedPlate>
    
    /**
     * Initialize a new game with specified mode
     */
    init(mode: GameMode, name: String? = nil) {
        self.id = UUID()
        self.mode = mode
        self.name = name
        self.createdDate = Date()
        self.lastPlayedDate = Date()
        self.collectedPlates = Set<CollectedPlate>()
    }
    
    /**
     * Get the total number of plates collected in this game
     * Used for progress display and achievements
     */
    var plateCount: Int {
        return collectedPlates.count
    }
    
    /**
     * Get the number of states with at least one collected plate
     * Useful for both game modes to show geographic progress
     */
    var stateCount: Int {
        return Set(collectedPlates.map { $0.state }).count
    }
    
    /**
     * Check if a specific plate has been collected in this game
     */
    func hasCollected(state: String, plateTitle: String) -> Bool {
        return collectedPlates.contains { plate in
            plate.state == state && plate.plateTitle == plateTitle
        }
    }
    
    /**
     * Add a plate to this game's collection
     * Returns true if successfully added, false if already exists
     */
    mutating func collectPlate(metadata: PlateMetadata) -> Bool {
        let collectedPlate = CollectedPlate(
            state: metadata.state,
            plateTitle: metadata.plateTitle,
            plateImage: metadata.plateImage,
            collectedDate: Date(),
            category: metadata.category,
            rarity: metadata.rarity
        )
        
        // For State Collection mode, only allow one plate per state
        if mode == .stateCollection {
            // Remove any existing plate from this state
            collectedPlates.removeAll { $0.state == metadata.state }
        }
        
        let (inserted, _) = collectedPlates.insert(collectedPlate)
        if inserted {
            lastPlayedDate = Date()
        }
        return inserted
    }
    
    /**
     * Remove a plate from this game's collection
     * Used for undo functionality when users make mistakes
     */
    mutating func removePlate(state: String, plateTitle: String) -> Bool {
        let beforeCount = collectedPlates.count
        collectedPlates.removeAll { plate in
            plate.state == state && plate.plateTitle == plateTitle
        }
        let removed = collectedPlates.count < beforeCount
        if removed {
            lastPlayedDate = Date()
        }
        return removed
    }
    
    /**
     * Get all collected plates for a specific state
     * Used for state-specific progress views
     */
    func platesForState(_ state: String) -> [CollectedPlate] {
        return collectedPlates.filter { $0.state == state }.sorted { $0.collectedDate < $1.collectedDate }
    }
    
    /**
     * Get progress summary by state for map visualization
     * Returns dictionary of state -> plate count
     */
    var stateProgress: [String: Int] {
        var progress: [String: Int] = [:]
        for plate in collectedPlates {
            progress[plate.state, default: 0] += 1
        }
        return progress
    }
    
    /**
     * Calculate total score based on plate rarity
     * Used for achievements and leaderboards
     */
    var totalScore: Int {
        return collectedPlates.reduce(0) { total, plate in
            total + (plate.rarity?.pointValue ?? 1)
        }
    }
}

/**
 * Game modes supported by the app
 * Each mode has different collection rules and objectives
 */
enum GameMode: String, CaseIterable, Codable {
    case stateCollection = "state_collection"
    case plateCollection = "plate_collection"
    
    var displayName: String {
        switch self {
        case .stateCollection: return "State Collection"
        case .plateCollection: return "Plate Collection"
        }
    }
    
    var description: String {
        switch self {
        case .stateCollection: return "Collect one plate from each state (50 total)"
        case .plateCollection: return "Collect as many unique plates as possible"
        }
    }
    
    /**
     * Maximum theoretical completion for each mode
     * Used for progress calculation and achievements
     */
    var maxCompletion: Int {
        switch self {
        case .stateCollection: return 50 // One per state
        case .plateCollection: return Int.max // Unlimited
        }
    }
}

/**
 * Individual plate collection record
 * Tracks when and which plates were collected in each game
 */
struct CollectedPlate: Codable, Hashable, Identifiable {
    let id = UUID()
    let state: String
    let plateTitle: String
    let plateImage: String
    let collectedDate: Date
    let category: PlateCategory?
    let rarity: PlateRarity?
    
    /**
     * Hash based on state and plate title for Set operations
     * Ensures no duplicate plates can be collected in the same game
     */
    func hash(into hasher: inout Hasher) {
        hasher.combine(state)
        hasher.combine(plateTitle)
    }
    
    /**
     * Equality based on state and plate title
     * Two plates are considered the same if they're from the same state with same title
     */
    static func == (lhs: CollectedPlate, rhs: CollectedPlate) -> Bool {
        return lhs.state == rhs.state && lhs.plateTitle == rhs.plateTitle
    }
}

/**
 * User preferences and recent activity tracking
 * Optimizes the user experience for frequent operations
 */
struct UserPreferences: Codable {
    var lastSelectedState: String?
    var recentStates: [String]
    var defaultGameMode: GameMode
    
    init() {
        self.lastSelectedState = nil
        self.recentStates = []
        self.defaultGameMode = .stateCollection
    }
    
    /**
     * Add a state to the recent list, maintaining max 3 items
     * Most recent states appear at the top of selection interface
     */
    mutating func addRecentState(_ state: String) {
        lastSelectedState = state
        
        // Remove if already exists to avoid duplicates
        recentStates.removeAll { $0 == state }
        
        // Add to front and limit to 3 items
        recentStates.insert(state, at: 0)
        if recentStates.count > 3 {
            recentStates.removeLast()
        }
    }
}