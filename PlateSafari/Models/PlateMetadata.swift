//
//  PlateMetadata.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import Foundation

/**
 * Core data model for license plate metadata
 * Supports both basic and enhanced metadata with graceful fallbacks
 */
struct PlateMetadata: Codable, Identifiable, Hashable {
    let id = UUID()
    
    // MARK: - Basic Metadata (always available)
    let state: String
    let plateTitle: String
    let plateImage: String
    
    // MARK: - Enhanced Metadata (optional, from experimental classifications)
    let colorBackground: String?
    let textColor: String?
    let visualElements: String?
    let category: PlateCategory?
    let rarity: PlateRarity?
    let layoutStyle: String?
    let confidenceScore: Double?
    let notes: String?
    let source: String?
    
    /**
     * Initialize from basic CSV data
     * Used for backward compatibility and fallback scenarios
     */
    init(state: String, plateTitle: String, plateImage: String) {
        self.state = state
        self.plateTitle = plateTitle
        self.plateImage = plateImage
        
        // Enhanced fields default to nil for basic data
        self.colorBackground = nil
        self.textColor = nil
        self.visualElements = nil
        self.category = nil
        self.rarity = nil
        self.layoutStyle = nil
        self.confidenceScore = nil
        self.notes = nil
        self.source = nil
    }
    
    /**
     * Initialize from enhanced CSV data
     * Includes experimental classifications with confidence scores
     */
    init(state: String, plateTitle: String, plateImage: String,
         colorBackground: String?, textColor: String?, visualElements: String?,
         category: String?, rarity: String?, layoutStyle: String?,
         confidenceScore: Double?, notes: String?, source: String?) {
        self.state = state
        self.plateTitle = plateTitle
        self.plateImage = plateImage
        self.colorBackground = colorBackground
        self.textColor = textColor
        self.visualElements = visualElements
        self.category = PlateCategory.from(string: category)
        self.rarity = PlateRarity.from(string: rarity)
        self.layoutStyle = layoutStyle
        self.confidenceScore = confidenceScore
        self.notes = notes
        self.source = source
    }
    
    /**
     * Computed property to check if enhanced metadata is available
     * Used by UI components to show/hide advanced filtering options
     */
    var hasEnhancedMetadata: Bool {
        return category != nil || rarity != nil || confidenceScore != nil
    }
    
    /**
     * Get the image file URL relative to the SourcePlateImages directory
     */
    var imageURL: URL? {
        guard let bundlePath = Bundle.main.path(forResource: "SourcePlateImages", ofType: nil) else {
            return nil
        }
        return URL(fileURLWithPath: bundlePath)
            .appendingPathComponent(state)
            .appendingPathComponent(plateImage)
    }
}

/**
 * Plate categories for filtering and organization
 * Based on experimental classification data
 */
enum PlateCategory: String, CaseIterable, Codable {
    case military = "military"
    case university = "university" 
    case causeCharity = "cause_charity"
    case sports = "sports"
    case professional = "professional"
    case government = "government"
    case specialty = "specialty"
    case standard = "standard"
    
    static func from(string: String?) -> PlateCategory? {
        guard let string = string else { return nil }
        return PlateCategory(rawValue: string.lowercased())
    }
    
    var displayName: String {
        switch self {
        case .causeCharity: return "Cause/Charity"
        case .military: return "Military/Veteran"
        case .university: return "University/College"
        case .sports: return "Sports"
        case .professional: return "Professional"
        case .government: return "Government"
        case .specialty: return "Specialty"
        case .standard: return "Standard"
        }
    }
}

/**
 * Plate rarity levels for collection game mechanics
 * Affects point values and achievement systems
 */
enum PlateRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case veryRare = "very_rare"
    case legendary = "legendary"
    
    static func from(string: String?) -> PlateRarity? {
        guard let string = string else { return nil }
        return PlateRarity(rawValue: string.lowercased().replacingOccurrences(of: " ", with: "_"))
    }
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .veryRare: return "Very Rare"
        case .legendary: return "Legendary"
        }
    }
    
    /**
     * Point values for different rarity levels
     * Used in scoring and achievement systems
     */
    var pointValue: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 5
        case .veryRare: return 10
        case .legendary: return 25
        }
    }
}