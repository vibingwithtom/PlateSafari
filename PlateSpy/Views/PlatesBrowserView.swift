//
//  PlatesBrowserView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Plate Gallery - browse license plates by state with search and filtering
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
        NavigationStack {
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
            .navigationTitle("Plate Gallery")
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
                AllStatesPlatesGridView(
                    plates: allStatesFilteredPlates,
                    searchText: searchText
                )
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
    
    /**
     * Get filtered plates from all states when no specific state is selected
     */
    private var allStatesFilteredPlates: [PlateMetadata] {
        var plates = plateDataService.plates
        
        // Apply search filter
        if !searchText.isEmpty {
            plates = plates.filter { plate in
                let fullStateName = USStatePositions.fullName(for: plate.state) ?? plate.state
                return plate.plateTitle.localizedCaseInsensitiveContains(searchText) ||
                       plate.state.localizedCaseInsensitiveContains(searchText) ||
                       fullStateName.localizedCaseInsensitiveContains(searchText)
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
        
        return plates.sorted { 
            if $0.state != $1.state {
                let fullName1 = USStatePositions.fullName(for: $0.state) ?? $0.state
                let fullName2 = USStatePositions.fullName(for: $1.state) ?? $1.state
                return fullName1 < fullName2
            }
            return $0.plateTitle < $1.plateTitle
        }
    }
}

/**
 * Compact state selection interface optimized for space efficiency
 */
struct StateSelectionView: View {
    @EnvironmentObject var plateDataService: PlateDataService
    @EnvironmentObject var gameManager: GameManagerService
    
    @Binding var selectedState: String?
    
    var body: some View {
        VStack(spacing: 12) {
            // Recent states (if any) - keep as horizontal scroll
            if !gameManager.userPreferences.recentStates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
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
            
            // Compact state picker
            CompactStatePicker(
                availableStates: plateDataService.availableStates,
                selectedState: $selectedState
            )
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
            Text(USStatePositions.fullName(for: state) ?? state)
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
 * Compact state picker that uses minimal vertical space
 */
struct CompactStatePicker: View {
    let availableStates: [String]
    @Binding var selectedState: String?
    @State private var showingStatePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(selectedState == nil ? "All States" : "Selected State")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Clear state selection button when state is selected
                if selectedState != nil {
                    Button("View All States") {
                        selectedState = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Compact state selector button
            Button(action: { showingStatePicker = true }) {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                    
                    Text(selectedState != nil ? (USStatePositions.fullName(for: selectedState!) ?? selectedState!) : "Select a state...")
                        .font(.body)
                        .fontWeight(selectedState != nil ? .medium : .regular)
                        .foregroundColor(selectedState != nil ? .primary : .secondary)
                    
                    Spacer()
                    
                    if selectedState != nil {
                        Button(action: { selectedState = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .sheet(isPresented: $showingStatePicker) {
                StatePickerSheet(
                    availableStates: availableStates,
                    selectedState: $selectedState
                )
            }
        }
    }
}

/**
 * Modal sheet for state selection
 */
struct StatePickerSheet: View {
    let availableStates: [String]
    @Binding var selectedState: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredStates: [String] {
        if searchText.isEmpty {
            return availableStates
        } else {
            return availableStates.filter { state in
                let stateName = USStatePositions.fullName(for: state) ?? state
                return state.localizedCaseInsensitiveContains(searchText) ||
                       stateName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search states...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // States list
                List {
                    ForEach(filteredStates, id: \.self) { state in
                        StatePickerRow(
                            state: state,
                            isSelected: selectedState == state,
                            onSelect: {
                                selectedState = state
                                dismiss()
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/**
 * Individual row in the state picker sheet
 */
struct StatePickerRow: View {
    let state: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(USStatePositions.fullName(for: state) ?? state)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(state)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
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
            GeometryReader { geometry in
                ScrollView {
                    LazyVGrid(columns: ResponsiveLayout.responsiveColumns(geometry: geometry, portraitColumns: 2, landscapeColumns: 4), spacing: 16) {
                        ForEach(plates) { plate in
                            PlateCardView(plate: plate)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

/**
 * Grid view of plates from all states with state grouping
 */
struct AllStatesPlatesGridView: View {
    let plates: [PlateMetadata]
    let searchText: String
    
    var body: some View {
        if plates.isEmpty {
            if searchText.isEmpty {
                AllStatesEmptyView()
            } else {
                EmptyPlatesView()
            }
        } else {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Group plates by state and display each group
                        ForEach(sortedStateKeys, id: \.self) { state in
                            VStack(alignment: .leading, spacing: 12) {
                                // State header
                                HStack {
                                    Text(USStatePositions.fullName(for: state) ?? state)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(groupedPlates[state]?.count ?? 0) plate\(groupedPlates[state]?.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                
                                // Plates grid for this state
                                LazyVGrid(columns: ResponsiveLayout.responsiveColumns(geometry: geometry, portraitColumns: 2, landscapeColumns: 4), spacing: 16) {
                                    ForEach(groupedPlates[state] ?? []) { plate in
                                        PlateCardView(plate: plate)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
    
    private var groupedPlates: [String: [PlateMetadata]] {
        Dictionary(grouping: plates) { $0.state }
    }
    
    private var sortedStateKeys: [String] {
        groupedPlates.keys.sorted { state1, state2 in
            let fullName1 = USStatePositions.fullName(for: state1) ?? state1
            let fullName2 = USStatePositions.fullName(for: state2) ?? state2
            return fullName1 < fullName2
        }
    }
}

/**
 * Empty state for all-states view when no search is active
 */
struct AllStatesEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Search across all states")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Type in the search bar above to find plates from any state")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * Individual plate card in the grid
 */
struct PlateCardView: View {
    let plate: PlateMetadata
    
    var body: some View {
        VStack(spacing: 8) {
            // Async plate image
            AsyncPlateImageView.card(plate: plate)
            
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