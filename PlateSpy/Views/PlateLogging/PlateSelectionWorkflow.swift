//
//  PlateSelectionWorkflow.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Complete plate logging workflow for games
 * Implements the three-step process: State Selection → Plate Selection → Confirmation
 */
struct PlateSelectionWorkflow: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: WorkflowStep = .stateSelection
    @State private var selectedState: String?
    @State private var selectedPlate: PlateMetadata?
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                WorkflowProgressView(currentStep: currentStep)
                
                // Main content based on current step
                switch currentStep {
                case .stateSelection:
                    StateSelectionStep(
                        selectedState: $selectedState,
                        onContinue: { proceedToPlateSelection() }
                    )
                    
                case .plateSelection:
                    PlateSelectionStep(
                        game: game,
                        state: selectedState ?? "",
                        selectedPlate: $selectedPlate,
                        onBack: { currentStep = .stateSelection },
                        onContinue: { proceedToConfirmation() }
                    )
                    
                case .confirmation:
                    PlateConfirmationStep(
                        game: game,
                        plate: selectedPlate!,
                        onBack: { currentStep = .plateSelection },
                        onConfirm: { logPlate() }
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
            }
            .overlay(
                // Success overlay
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
        }
    }
    
    /**
     * Navigate to plate selection step
     */
    private func proceedToPlateSelection() {
        guard selectedState != nil else { return }
        currentStep = .plateSelection
    }
    
    /**
     * Navigate to confirmation step
     */
    private func proceedToConfirmation() {
        guard selectedPlate != nil else { return }
        currentStep = .confirmation
    }
    
    /**
     * Log the plate to the game
     */
    private func logPlate() {
        guard let plate = selectedPlate else { return }
        
        let success = gameManager.collectPlate(gameId: game.id, metadata: plate)
        
        if success {
            showingSuccess = true
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if showingSuccess {
                    dismiss()
                }
            }
        } else {
            errorMessage = "This plate has already been collected in this game."
            showingError = true
        }
    }
}

/**
 * Workflow steps enum
 */
enum WorkflowStep: Int, CaseIterable {
    case stateSelection = 0
    case plateSelection = 1
    case confirmation = 2
    
    var title: String {
        switch self {
        case .stateSelection: return "Select State"
        case .plateSelection: return "Select Plate"
        case .confirmation: return "Confirm"
        }
    }
}

/**
 * Progress indicator for the workflow
 */
struct WorkflowProgressView: View {
    let currentStep: WorkflowStep
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(WorkflowStep.allCases, id: \.rawValue) { step in
                    VStack(spacing: 4) {
                        // Step circle
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color(.systemGray4))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(step.rawValue + 1)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(step.rawValue <= currentStep.rawValue ? .white : .secondary)
                            )
                        
                        // Step title
                        Text(step.title)
                            .font(.caption2)
                            .foregroundColor(step.rawValue <= currentStep.rawValue ? .primary : .secondary)
                    }
                    
                    // Connector line
                    if step.rawValue < WorkflowStep.allCases.count - 1 {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color(.systemGray4))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
}

/**
 * Step 1: State Selection
 * Shows recent states at top, then all states alphabetically
 */
struct StateSelectionStep: View {
    @EnvironmentObject var gameManager: GameManagerService
    @EnvironmentObject var plateDataService: PlateDataService
    
    @Binding var selectedState: String?
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Instructions
                InstructionCard(
                    icon: "map",
                    title: "Choose a State",
                    description: "Select the state where you spotted the license plate. Recent states appear at the top for quick access."
                )
                
                // Recent states section
                if !gameManager.userPreferences.recentStates.isEmpty {
                    StateSection(
                        title: "Recent States",
                        states: gameManager.userPreferences.recentStates,
                        selectedState: $selectedState
                    )
                }
                
                // All states section
                StateSection(
                    title: "All States",
                    states: plateDataService.availableStates,
                    selectedState: $selectedState
                )
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            // Continue button
            VStack {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedState != nil ? Color.blue : Color(.systemGray4))
                        .cornerRadius(12)
                }
                .disabled(selectedState == nil)
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
}

/**
 * Step 2: Plate Selection
 * Search and view plates within the selected state
 */
struct PlateSelectionStep: View {
    let game: Game
    let state: String
    @EnvironmentObject var plateDataService: PlateDataService
    @EnvironmentObject var gameManager: GameManagerService
    
    @Binding var selectedPlate: PlateMetadata?
    let onBack: () -> Void
    let onContinue: () -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: PlateCategory?
    @State private var showingFilters = false
    
    private var availablePlates: [PlateMetadata] {
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
    
    private var hasEnhancedMetadata: Bool {
        plateDataService.plates(for: state).contains { $0.hasEnhancedMetadata }
    }
    
    var body: some View {
        VStack {
            // State header with back button
            StateHeaderView(
                state: state,
                plateCount: availablePlates.count,
                onBack: onBack
            )
            
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search \(state) plates...")
                
                // Filter button (if enhanced metadata available)
                if hasEnhancedMetadata {
                    HStack {
                        Button(action: { showingFilters.toggle() }) {
                            HStack {
                                Image(systemName: "line.horizontal.3.decrease.circle")
                                Text("Filters")
                                if selectedCategory != nil {
                                    Text("(1)")
                                        .foregroundColor(.blue)
                                }
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if selectedCategory != nil {
                            Button("Clear") {
                                selectedCategory = nil
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Plates grid
            PlateSelectionGrid(
                plates: availablePlates,
                game: game,
                selectedPlate: $selectedPlate
            )
        }
        .safeAreaInset(edge: .bottom) {
            // Continue button
            VStack {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPlate != nil ? Color.blue : Color(.systemGray4))
                        .cornerRadius(12)
                }
                .disabled(selectedPlate == nil)
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(selectedCategory: $selectedCategory)
        }
    }
}

/**
 * Step 3: Confirmation
 * Final review before logging the plate
 */
struct PlateConfirmationStep: View {
    let game: Game
    let plate: PlateMetadata
    @EnvironmentObject var gameManager: GameManagerService
    
    let onBack: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Confirmation header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Ready to Log")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Please confirm the details below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Plate details card
                PlateDetailCard(plate: plate)
                
                // Game context
                GameContextCard(game: game)
                
                // Already collected warning (if applicable)
                if gameManager.isPlateCollected(gameId: game.id, state: plate.state, plateTitle: plate.plateTitle) {
                    WarningCard(
                        message: "This plate has already been collected in this game. Logging it again will not change your progress."
                    )
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text("Log This Plate")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                Button(action: onBack) {
                    Text("Back to Selection")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    PlateSelectionWorkflow(game: Game(mode: .stateCollection, name: "Test Game"))
        .environmentObject(GameManagerService())
        .environmentObject(PlateDataService())
}