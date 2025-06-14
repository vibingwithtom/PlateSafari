//
//  StreamlinedPlateLoggingView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/14/25.
//

import SwiftUI

/**
 * Streamlined plate logging workflow - reduces 3 screens to 1-2 screens
 * Combines state and plate selection with smart defaults and quick actions
 */
struct StreamlinedPlateLoggingView: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedState: String?
    @State private var selectedPlate: PlateMetadata?
    @State private var searchText = ""
    @State private var selectedCategory: PlateCategory?
    @State private var showingFilters = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick state selector header
                StateQuickSelector(
                    selectedState: $selectedState,
                    searchText: $searchText,
                    selectedCategory: $selectedCategory
                )
                
                Divider()
                
                // Main content area
                if let state = selectedState {
                    // Plate selection with integrated search
                    StreamlinedPlateGrid(
                        game: game,
                        state: state,
                        searchText: searchText,
                        selectedCategory: selectedCategory,
                        selectedPlate: $selectedPlate,
                        showingFilters: $showingFilters
                    )
                } else {
                    // Smart state suggestions
                    StateSuggestionsView(
                        onStateSelected: { state in
                            selectedState = state
                        }
                    )
                }
            }
            .navigationTitle("Log Plate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log") {
                        quickLogPlate()
                    }
                    .disabled(selectedPlate == nil || isLoading)
                    .fontWeight(.semibold)
                }
            }
            .overlay(
                Group {
                    if showingSuccess {
                        SuccessOverlay {
                            dismiss()
                        }
                    }
                }
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(selectedCategory: $selectedCategory)
            }
        }
    }
    
    /**
     * Quick log with minimal confirmation - bypasses confirmation screen
     */
    private func quickLogPlate() {
        guard let plate = selectedPlate else { return }
        
        isLoading = true
        
        // Check if already collected and show warning
        if gameManager.isPlateCollected(gameId: game.id, state: plate.state, plateTitle: plate.plateTitle) {
            errorMessage = "This plate has already been collected in this game."
            showingError = true
            isLoading = false
            return
        }
        
        // Log the plate
        let success = gameManager.collectPlate(gameId: game.id, metadata: plate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isLoading = false
            
            if success {
                showingSuccess = true
                // Auto-dismiss after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if showingSuccess {
                        dismiss()
                    }
                }
            } else {
                errorMessage = "Failed to log plate. Please try again."
                showingError = true
            }
        }
    }
}

/**
 * Compact state selector with search integration
 */
struct StateQuickSelector: View {
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    
    @Binding var selectedState: String?
    @Binding var searchText: String
    @Binding var selectedCategory: PlateCategory?
    
    @State private var showingStatePicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            // State and search row
            HStack(spacing: 12) {
                // State selector button
                Button(action: { showingStatePicker = true }) {
                    HStack {
                        Image(systemName: "map")
                            .foregroundColor(.blue)
                        
                        Text(selectedState ?? "Select State")
                            .font(.subheadline)
                            .fontWeight(selectedState != nil ? .medium : .regular)
                            .foregroundColor(selectedState != nil ? .primary : .secondary)
                        
                        Spacer()
                        
                        if selectedState != nil {
                            Button(action: { 
                                selectedState = nil
                                searchText = ""
                                selectedCategory = nil
                            }) {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Integrated search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search plates...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Quick filters (if enhanced metadata available)
            if hasEnhancedMetadata {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All Categories",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(PlateCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingStatePicker) {
            StatePickerSheet(
                availableStates: plateDataService.availableStates,
                selectedState: $selectedState
            )
        }
    }
    
    private var hasEnhancedMetadata: Bool {
        plateDataService.plates.contains { $0.hasEnhancedMetadata }
    }
}

/**
 * Smart state suggestions when no state is selected
 */
struct StateSuggestionsView: View {
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    
    let onStateSelected: (String) -> Void
    @State private var showingAllStates = false
    
    private var recentStates: [String] {
        gameManager.userPreferences.recentStates
    }
    
    @State private var suggestedStates: [String] = []
    
    private func loadSuggestedStates() {
        // Show states with most plates collected in current games
        let allCollectedStates = gameManager.games.flatMap { game in
            game.collectedPlates.map { $0.state }
        }
        let stateCounts = Dictionary(grouping: allCollectedStates, by: { $0 })
            .mapValues { $0.count }
        
        suggestedStates = stateCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(spacing: 8) {
                    Image(systemName: "location")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Choose a State")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select the state where you spotted the license plate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Recent states
                if !recentStates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent States")
                                .font(.headline)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(recentStates, id: \.self) { state in
                                StateQuickButton(
                                    state: state,
                                    subtitle: "Recent",
                                    onTap: { onStateSelected(state) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Suggested states based on collection history
                if !suggestedStates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Active States")
                                .font(.headline)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(suggestedStates, id: \.self) { state in
                                StateQuickButton(
                                    state: state,
                                    subtitle: "Active",
                                    onTap: { onStateSelected(state) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Call to action
                VStack(spacing: 12) {
                    Button(action: { showingAllStates = true }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Browse All States")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadSuggestedStates()
        }
        .sheet(isPresented: $showingAllStates) {
            CustomStatePickerSheet(
                availableStates: plateDataService.availableStates,
                onStateSelected: { state in
                    onStateSelected(state)
                    showingAllStates = false
                }
            )
        }
    }
}

/**
 * Quick state selection button
 */
struct StateQuickButton: View {
    let state: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(state)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * Streamlined plate grid with quick selection
 */
struct StreamlinedPlateGrid: View {
    let game: Game
    let state: String
    let searchText: String
    let selectedCategory: PlateCategory?
    @EnvironmentObject var plateDataService: PlateDataService
    @EnvironmentObject var gameManager: GameManagerService
    
    @Binding var selectedPlate: PlateMetadata?
    @Binding var showingFilters: Bool
    
    private var filteredPlates: [PlateMetadata] {
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
        
        return plates.sorted { $0.plateTitle < $1.plateTitle }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if filteredPlates.isEmpty {
                    EmptyPlateSelectionView()
                        .frame(height: geometry.size.height * 0.6)
                } else {
                    LazyVGrid(columns: ResponsiveLayout.responsiveColumns(geometry: geometry, portraitColumns: 2, landscapeColumns: 3), spacing: 12) {
                        ForEach(filteredPlates) { plate in
                            QuickPlateCard(
                                plate: plate,
                                isSelected: selectedPlate?.id == plate.id,
                                isAlreadyCollected: gameManager.isPlateCollected(
                                    gameId: game.id,
                                    state: plate.state,
                                    plateTitle: plate.plateTitle
                                ),
                                onSelect: { selectedPlate = plate }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

/**
 * Quick plate selection card with enhanced visual feedback
 */
struct QuickPlateCard: View {
    let plate: PlateMetadata
    let isSelected: Bool
    let isAlreadyCollected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Plate image
                PlateImageView(plate: plate)
                    .aspectRatio(2, contentMode: .fit)
                    .overlay(
                        Group {
                            if isAlreadyCollected {
                                Rectangle()
                                    .fill(Color.green.opacity(0.8))
                                    .overlay(
                                        VStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                            Text("Collected")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                        }
                                    )
                            }
                        }
                    )
                
                // Plate title
                Text(plate.plateTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Enhanced metadata badges
                if plate.hasEnhancedMetadata {
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(radius: isSelected ? 6 : 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * Quick filter chip for categories
 */
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
 * Custom state picker sheet with callback support
 */
struct CustomStatePickerSheet: View {
    let availableStates: [String]
    let onStateSelected: (String) -> Void
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
                        CustomStatePickerRow(
                            state: state,
                            onSelect: {
                                onStateSelected(state)
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
 * Individual row in the custom state picker sheet
 */
struct CustomStatePickerRow: View {
    let state: String
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let fullName = USStatePositions.fullName(for: state) {
                        Text(fullName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StreamlinedPlateLoggingView(game: Game(mode: .stateCollection, name: "Test Game"))
        .environmentObject(GameManagerService())
        .environmentObject(PlateDataService())
}