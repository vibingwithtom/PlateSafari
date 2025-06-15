//
//  AllCollectedPlatesView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/15/25.
//

import SwiftUI

/**
 * View showing all plates collected in a specific game session
 * Displays plates grouped by state with search and filter capabilities
 */
struct AllCollectedPlatesView: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedState: String?
    @State private var sortOption: SortOption = .dateCollected
    
    enum SortOption: String, CaseIterable {
        case dateCollected = "Date Collected"
        case plateTitle = "Plate Name"
        case state = "State"
        
        var systemImage: String {
            switch self {
            case .dateCollected: return "clock"
            case .plateTitle: return "textformat.abc"
            case .state: return "map"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filter controls
                SearchAndFilterControls(
                    searchText: $searchText,
                    selectedState: $selectedState,
                    sortOption: $sortOption,
                    availableStates: collectingStates
                )
                
                Divider()
                
                // Main content
                if game.collectedPlates.isEmpty {
                    EmptyCollectionView()
                } else if filteredPlates.isEmpty {
                    EmptySearchResultsView(searchText: searchText)
                } else {
                    CollectedPlatesGrid(
                        plates: filteredPlates,
                        sortOption: sortOption
                    )
                }
            }
            .navigationTitle("Collected Plates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Text("\(filteredPlates.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Text(filteredPlates.count == 1 ? "plate" : "plates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    /**
     * Get all plates with search and state filters applied
     */
    private var filteredPlates: [CollectedPlate] {
        var plates = Array(game.collectedPlates)
        
        // Apply search filter
        if !searchText.isEmpty {
            plates = plates.filter { plate in
                let fullStateName = USStatePositions.fullName(for: plate.state) ?? plate.state
                return plate.plateTitle.localizedCaseInsensitiveContains(searchText) ||
                       plate.state.localizedCaseInsensitiveContains(searchText) ||
                       fullStateName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply state filter
        if let selectedState = selectedState {
            plates = plates.filter { $0.state == selectedState }
        }
        
        return plates
    }
    
    /**
     * Get unique states that have collected plates
     */
    private var collectingStates: [String] {
        Set(game.collectedPlates.map { $0.state })
            .sorted { state1, state2 in
                let fullName1 = USStatePositions.fullName(for: state1) ?? state1
                let fullName2 = USStatePositions.fullName(for: state2) ?? state2
                return fullName1 < fullName2
            }
    }
}

/**
 * Search and filter controls for collected plates
 */
struct SearchAndFilterControls: View {
    @Binding var searchText: String
    @Binding var selectedState: String?
    @Binding var sortOption: AllCollectedPlatesView.SortOption
    let availableStates: [String]
    
    @State private var showingStateFilter = false
    @State private var showingSortOptions = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search plates or states...", text: $searchText)
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
            
            // Filter and sort controls
            HStack(spacing: 12) {
                // State filter button
                Button(action: { showingStateFilter = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "map")
                        Text(selectedState != nil ? (USStatePositions.fullName(for: selectedState!) ?? selectedState!) : "All States")
                        if selectedState != nil {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .onTapGesture {
                                    selectedState = nil
                                }
                        } else {
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Sort button
                Button(action: { showingSortOptions = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: sortOption.systemImage)
                        Text("Sort")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingStateFilter) {
            StateFilterSheet(
                availableStates: availableStates,
                selectedState: $selectedState
            )
        }
        .sheet(isPresented: $showingSortOptions) {
            SortOptionsSheet(selectedSort: $sortOption)
        }
    }
}

/**
 * Grid displaying collected plates
 */
struct CollectedPlatesGrid: View {
    let plates: [CollectedPlate]
    let sortOption: AllCollectedPlatesView.SortOption
    
    private var sortedPlates: [CollectedPlate] {
        switch sortOption {
        case .dateCollected:
            return plates.sorted { $0.collectedDate > $1.collectedDate }
        case .plateTitle:
            return plates.sorted { $0.plateTitle < $1.plateTitle }
        case .state:
            return plates.sorted { state1, state2 in
                let fullName1 = USStatePositions.fullName(for: state1.state) ?? state1.state
                let fullName2 = USStatePositions.fullName(for: state2.state) ?? state2.state
                if fullName1 != fullName2 {
                    return fullName1 < fullName2
                }
                return state1.plateTitle < state2.plateTitle
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: ResponsiveLayout.responsiveColumns(geometry: geometry, portraitColumns: 2, landscapeColumns: 4), spacing: 16) {
                    ForEach(sortedPlates, id: \.id) { plate in
                        CollectedPlateCard(plate: plate)
                    }
                }
                .padding()
            }
        }
    }
}

/**
 * Individual collected plate card
 */
struct CollectedPlateCard: View {
    let plate: CollectedPlate
    @State private var showingPlateDetail = false
    
    private var plateMetadata: PlateMetadata {
        PlateMetadata(
            state: plate.state,
            plateTitle: plate.plateTitle,
            plateImage: plate.plateImage,
            colorBackground: nil,
            textColor: nil,
            visualElements: nil,
            category: plate.category?.rawValue,
            rarity: plate.rarity?.rawValue,
            layoutStyle: nil,
            confidenceScore: nil,
            notes: nil,
            source: plate.source
        )
    }
    
    var body: some View {
        Button(action: { showingPlateDetail = true }) {
            VStack(spacing: 8) {
                // Plate image
                AsyncPlateImageView(
                    plate: plateMetadata,
                    cornerRadius: 8
                )
                .aspectRatio(2, contentMode: .fit)
                
                // Plate info
                VStack(spacing: 4) {
                    Text(plate.plateTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(USStatePositions.fullName(for: plate.state) ?? plate.state)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(plate.collectedDate))
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                // Enhanced metadata badges
                if plate.category != nil || plate.rarity != nil {
                    HStack(spacing: 4) {
                        if let category = plate.category {
                            CategoryBadge(category: category)
                        }
                        
                        if let rarity = plate.rarity {
                            RarityBadge(rarity: rarity)
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPlateDetail) {
            PlateDetailView(plate: plateMetadata, game: nil)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/**
 * Empty state when no plates collected
 */
struct EmptyCollectionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Plates Collected")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Start collecting plates to see them here!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * Empty state when search/filter returns no results
 */
struct EmptySearchResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Matching Plates")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Text("No plates found matching '\(searchText)'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No plates found for the selected filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * State filter selection sheet
 */
struct StateFilterSheet: View {
    let availableStates: [String]
    @Binding var selectedState: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // All states option
                Button(action: {
                    selectedState = nil
                    dismiss()
                }) {
                    HStack {
                        Text("All States")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedState == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                
                // Individual states
                ForEach(availableStates, id: \.self) { state in
                    Button(action: {
                        selectedState = state
                        dismiss()
                    }) {
                        HStack {
                            Text(USStatePositions.fullName(for: state) ?? state)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedState == state {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                }
            }
            .navigationTitle("Filter by State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/**
 * Sort options selection sheet
 */
struct SortOptionsSheet: View {
    @Binding var selectedSort: AllCollectedPlatesView.SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AllCollectedPlatesView.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedSort = option
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: option.systemImage)
                                .frame(width: 20)
                            
                            Text(option.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedSort == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    AllCollectedPlatesView(game: Game(mode: .stateCollection, name: "Test Game"))
        .environmentObject(GameManagerService())
}