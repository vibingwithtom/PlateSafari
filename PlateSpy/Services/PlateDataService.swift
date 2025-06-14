//
//  PlateDataService.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import Foundation

/**
 * Service for loading and managing license plate data
 * Supports both basic and enhanced CSV formats with graceful fallbacks
 */
class PlateDataService: ObservableObject {
    @Published var plates: [PlateMetadata] = []
    @Published var isLoading = false
    @Published var loadingError: PlateDataError?
    
    private let csvQueue = DispatchQueue(label: "csv.processing", qos: .userInitiated)
    
    /**
     * Load plate data from CSV files
     * Attempts enhanced format first, falls back to basic format
     */
    func loadPlateData() {
        isLoading = true
        loadingError = nil
        
        csvQueue.async { [weak self] in
            do {
                let loadedPlates = try self?.loadFromCSV() ?? []
                
                DispatchQueue.main.async {
                    self?.plates = loadedPlates
                    self?.isLoading = false
                    print("✅ Loaded \(loadedPlates.count) plates successfully")
                }
            } catch {
                DispatchQueue.main.async {
                    self?.loadingError = error as? PlateDataError ?? .unknownError
                    self?.isLoading = false
                    print("❌ Failed to load plate data: \(error)")
                }
            }
        }
    }
    
    /**
     * Attempt to load from enhanced CSV, fallback to basic CSV
     */
    private func loadFromCSV() throws -> [PlateMetadata] {
        // Try enhanced format first
        if let enhancedData = loadEnhancedCSV() {
            print("📊 Using enhanced plate metadata with classifications")
            return enhancedData
        }
        
        // Fallback to basic format
        print("📋 Using basic plate metadata (no classifications)")
        return try loadBasicCSV()
    }
    
    /**
     * Load enhanced CSV with experimental classifications
     * Returns nil if file doesn't exist or has parsing errors
     */
    private func loadEnhancedCSV() -> [PlateMetadata]? {
        guard let enhancedPath = findCSVFile(withColumns: ["color_bg", "category", "rarity"]),
              let csvContent = try? String(contentsOfFile: enhancedPath) else {
            return nil
        }
        
        do {
            return try parseEnhancedCSV(csvContent)
        } catch {
            print("⚠️ Enhanced CSV parsing failed, will fallback to basic: \(error)")
            return nil
        }
    }
    
    /**
     * Load basic CSV format as fallback
     * Required format: state,plate_title,plate_img
     */
    private func loadBasicCSV() throws -> [PlateMetadata] {
        guard let basicPath = findCSVFile(withColumns: ["state", "plate_title", "plate_img"]),
              let csvContent = try? String(contentsOfFile: basicPath) else {
            throw PlateDataError.csvFileNotFound
        }
        
        return try parseBasicCSV(csvContent)
    }
    
    /**
     * Find CSV file in project that contains required columns
     */
    private func findCSVFile(withColumns requiredColumns: [String]) -> String? {
        let possiblePaths = [
            Bundle.main.path(forResource: "plate_metadata_enhanced", ofType: "csv"),
            Bundle.main.path(forResource: "plate_metadata", ofType: "csv"),
            // Also check project directory for development
            "/Users/raia/XCodeProjects/PlateSpy/plate_metadata_enhanced.csv",
            "/Users/raia/XCodeProjects/PlateSpy/plate_metadata.csv"
        ]
        
        for path in possiblePaths.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: path),
               let content = try? String(contentsOfFile: path),
               let firstLine = content.components(separatedBy: .newlines).first {
                
                let headers = firstLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let hasAllColumns = requiredColumns.allSatisfy { headers.contains($0) }
                
                if hasAllColumns {
                    print("📁 Found CSV file: \(path)")
                    return path
                }
            }
        }
        
        return nil
    }
    
    /**
     * Parse enhanced CSV format with all metadata fields
     */
    private func parseEnhancedCSV(_ csvContent: String) throws -> [PlateMetadata] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw PlateDataError.emptyCSV }
        
        let headers = parseCSVLine(lines[0])
        var plates: [PlateMetadata] = []
        
        for (index, line) in lines.dropFirst().enumerated() {
            let lineNumber = index + 2 // Account for header and 0-based indexing
            
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            
            do {
                let values = parseCSVLine(line)
                guard values.count >= 3 else { 
                    // Skip lines with insufficient data (like empty URL-only lines)
                    continue 
                }
                
                // Check if required fields have actual content (not just empty strings)
                guard !values[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !values[1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !values[2].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    // Skip lines where required fields are empty
                    continue
                }
                
                let plate = try createEnhancedPlate(from: values, headers: headers, lineNumber: lineNumber)
                plates.append(plate)
                
            } catch {
                print("⚠️ Skipping line \(lineNumber): \(error)")
                continue
            }
        }
        
        return plates
    }
    
    /**
     * Parse basic CSV format with minimal fields
     */
    private func parseBasicCSV(_ csvContent: String) throws -> [PlateMetadata] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw PlateDataError.emptyCSV }
        
        var plates: [PlateMetadata] = []
        
        for line in lines.dropFirst() {
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            
            let values = parseCSVLine(line)
            guard values.count >= 3 else { continue }
            
            let plate = PlateMetadata(
                state: values[0].trimmingCharacters(in: .whitespacesAndNewlines),
                plateTitle: values[1].trimmingCharacters(in: .whitespacesAndNewlines),
                plateImage: values[2].trimmingCharacters(in: .whitespacesAndNewlines)
            )
            plates.append(plate)
        }
        
        return plates
    }
    
    /**
     * Create enhanced plate metadata from CSV values and headers
     */
    private func createEnhancedPlate(from values: [String], headers: [String], lineNumber: Int) throws -> PlateMetadata {
        func getValue(for column: String) -> String? {
            guard let index = headers.firstIndex(of: column), index < values.count else { return nil }
            let value = values[index].trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
        
        guard let state = getValue(for: "state"),
              let plateTitle = getValue(for: "plate_title"),
              let plateImage = getValue(for: "plate_img") else {
            throw PlateDataError.missingRequiredFields(line: lineNumber)
        }
        
        let confidenceScore = getValue(for: "confidence_score").flatMap { Double($0) }
        
        return PlateMetadata(
            state: state,
            plateTitle: plateTitle,
            plateImage: plateImage,
            colorBackground: getValue(for: "color_bg"),
            textColor: getValue(for: "text_color"),
            visualElements: getValue(for: "visual_elements"),
            category: getValue(for: "category"),
            rarity: getValue(for: "rarity"),
            layoutStyle: getValue(for: "layout_style"),
            confidenceScore: confidenceScore,
            notes: getValue(for: "notes"),
            source: getValue(for: "source")
        )
    }
    
    /**
     * Parse CSV line handling quoted fields with commas
     */
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            
            i = line.index(after: i)
        }
        
        fields.append(currentField) // Add the last field
        return fields
    }
    
    /**
     * Get all unique states in the dataset
     * Used for state selection interfaces
     */
    var availableStates: [String] {
        let states = Set(plates.map { $0.state })
        return Array(states).sorted()
    }
    
    /**
     * Get plates for a specific state
     * Used for state-specific browsing
     */
    func plates(for state: String) -> [PlateMetadata] {
        return plates.filter { $0.state == state }
    }
    
    /**
     * Filter plates by category (enhanced metadata)
     * Returns all plates if category filtering not available
     */
    func plates(category: PlateCategory) -> [PlateMetadata] {
        return plates.filter { $0.category == category }
    }
    
    /**
     * Filter plates by rarity (enhanced metadata)
     * Returns all plates if rarity filtering not available
     */
    func plates(rarity: PlateRarity) -> [PlateMetadata] {
        return plates.filter { $0.rarity == rarity }
    }
}

/**
 * Errors that can occur during plate data loading
 */
enum PlateDataError: Error, LocalizedError {
    case csvFileNotFound
    case emptyCSV
    case missingRequiredFields(line: Int)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .csvFileNotFound:
            return "Could not find plate metadata CSV file"
        case .emptyCSV:
            return "CSV file is empty or invalid"
        case .missingRequiredFields(let line):
            return "Missing required fields on line \(line)"
        case .unknownError:
            return "An unknown error occurred while loading plate data"
        }
    }
}