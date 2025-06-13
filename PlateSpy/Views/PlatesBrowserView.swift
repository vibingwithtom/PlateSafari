//
//  PlatesBrowserView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Browse license plates by state with search and filtering
 * Supports both basic browsing and enhanced filtering when metadata available
 */
struct PlatesBrowserView: View {
    @EnvironmentObject var plateDataService: PlateDataService
    @EnvironmentObject var gameManager: GameManagerService
    
    @State private var selectedState: String?
    @State private var searchText = ""
    @State private var selectedCategory: PlateCategory?
    @State private var selectedRarity: PlateRarity?
    
    var body: some View {
        NavigationView {
            VStack {
                if plateDataService.isLoading {
                    LoadingView(message: "Loading license plates...")
                } else if let error = plateDataService.loadingError {
                    ErrorView(error: error) {
                        plateDataService.loadPlateData()
                    }
                } else {
                    BrowserContentView(
                        selectedState: $selectedState,
                        searchText: $searchText,
                        selectedCategory: $selectedCategory,
                        selectedRarity: $selectedRarity
                    )
                }
            }
            .navigationTitle("Browse Plates")
            .searchable(text: $searchText, prompt: "Search plates...")
        }
    }
}

/**
 * Main browser content when data is loaded
 */
struct BrowserContentView: View {
    @EnvironmentObject var plateDataService: PlateDataService
    
    @Binding var selectedState: String?
    @Binding var searchText: String
    @Binding var selectedCategory: PlateCategory?
    @Binding var selectedRarity: PlateRarity?
    
    var body: some View {
        VStack {
            // State selection
            StateSelectionView(selectedState: $selectedState)
            
            // Filters (if enhanced metadata available)
            if hasEnhancedMetadata {
                FilterView(
                    selectedCategory: $selectedCategory,
                    selectedRarity: $selectedRarity
                )
            }
            
            // Plates grid or list
            if let state = selectedState {
                PlatesGridView(
                    plates: filteredPlates(for: state),
                    state: state
                )
            } else {
                PlaceholderView()
            }
        }
    }
    
    /**
     * Check if any plates have enhanced metadata
     */
    private var hasEnhancedMetadata: Bool {
        plateDataService.plates.contains { $0.hasEnhancedMetadata }
    }
    
    /**
     * Get filtered plates for the selected state
     */
    private func filteredPlates(for state: String) -> [PlateMetadata] {
        var plates = plateDataService.plates(for: state)
        
        // Apply search filter
        if !searchText.isEmpty {
            plates = plates.filter { plate in
                plate.plateTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            plates = plates.filter { $0.category == category }
        }
        
        // Apply rarity filter
        if let rarity = selectedRarity {
            plates = plates.filter { $0.rarity == rarity }
        }
        
        return plates.sorted { $0.plateTitle < $1.plateTitle }
    }
}

/**
 * State selection interface with recent states at top
 */
struct StateSelectionView: View {
    @EnvironmentObject var plateDataService: PlateDataService
    @EnvironmentObject var gameManager: GameManagerService
    
    @Binding var selectedState: String?
    
    var body: some View {
        VStack {
            // Recent states section
            if !gameManager.userPreferences.recentStates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(gameManager.userPreferences.recentStates, id: \.self) { state in
                                StateButton(
                                    state: state,
                                    isSelected: selectedState == state,
                                    action: { selectedState = state }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // All states section
            VStack(alignment: .leading, spacing: 8) {
                Text("All States")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(plateDataService.availableStates, id: \.self) { state in
                        StateButton(
                            state: state,
                            isSelected: selectedState == state,
                            action: { selectedState = state }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/**
 * Individual state selection button
 */
struct StateButton: View {
    let state: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(state)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * Filter controls for enhanced metadata
 */
struct FilterView: View {
    @Binding var selectedCategory: PlateCategory?
    @Binding var selectedRarity: PlateRarity?
    
    var body: some View {
        VStack {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterButton(
                        title: "All Categories",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(PlateCategory.allCases, id: \.self) { category in
                        FilterButton(
                            title: category.displayName,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Rarity filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterButton(
                        title: "All Rarities",
                        isSelected: selectedRarity == nil,
                        action: { selectedRarity = nil }
                    )
                    
                    ForEach(PlateRarity.allCases, id: \.self) { rarity in
                        FilterButton(
                            title: rarity.displayName,
                            isSelected: selectedRarity == rarity,
                            action: { selectedRarity = rarity }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/**
 * Individual filter button
 */
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * Grid view of plates for selected state
 */
struct PlatesGridView: View {
    let plates: [PlateMetadata]
    let state: String
    
    var body: some View {
        if plates.isEmpty {
            EmptyPlatesView()
        } else {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(plates) { plate in
                        PlateCardView(plate: plate)
                    }
                }
                .padding()
            }
        }
    }
}

/**
 * Individual plate card in the grid
 */
struct PlateCardView: View {
    let plate: PlateMetadata
    
    var body: some View {
        VStack(spacing: 8) {
            // Placeholder for plate image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .aspectRatio(2, contentMode: .fit)
                .overlay(
                    Image(systemName: "car.rear")
                        .font(.title)
                        .foregroundColor(.gray)
                )
            
            Text(plate.plateTitle)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/**
 * Placeholder when no state is selected
 */
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Select a state to browse plates")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * Empty state when no plates match filters
 */
struct EmptyPlatesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No plates found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlatesBrowserView()
        .environmentObject(PlateDataService())
        .environmentObject(GameManagerService())
}