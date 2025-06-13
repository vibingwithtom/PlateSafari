//
//  PlateLoggingComponents.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Reusable components for the plate logging workflow
 */

// MARK: - Instruction Card

/**
 * Instructional card with icon and description
 */
struct InstructionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - State Selection Components

/**
 * Section of states with title and grid layout
 */
struct StateSection: View {
    let title: String
    let states: [String]
    @Binding var selectedState: String?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(states, id: \.self) { state in
                    StateSelectionButton(
                        state: state,
                        isSelected: selectedState == state,
                        action: { selectedState = state }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * Individual state selection button
 */
struct StateSelectionButton: View {
    let state: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(state)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Plate Selection Components

/**
 * Header for plate selection step
 */
struct StateHeaderView: View {
    let state: String
    let plateCount: Int
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(state)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("\(plateCount) plates")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

/**
 * Search bar component
 */
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

/**
 * Plate selection grid
 */
struct PlateSelectionGrid: View {
    let plates: [PlateMetadata]
    let game: Game
    @Binding var selectedPlate: PlateMetadata?
    @EnvironmentObject var gameManager: GameManagerService
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    
    var body: some View {
        ScrollView {
            if plates.isEmpty {
                EmptyPlateSelectionView()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(plates) { plate in
                        PlateSelectionCard(
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

/**
 * Individual plate selection card
 */
struct PlateSelectionCard: View {
    let plate: PlateMetadata
    let isSelected: Bool
    let isAlreadyCollected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Plate image placeholder
                PlateImageView(plate: plate)
                    .aspectRatio(2, contentMode: .fit)
                    .overlay(
                        // Already collected overlay
                        Group {
                            if isAlreadyCollected {
                                Rectangle()
                                    .fill(Color.green.opacity(0.8))
                                    .overlay(
                                        VStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                            Text("Collected")
                                                .font(.caption)
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
                    .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(radius: isSelected ? 4 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/**
 * Plate image view using async loading service
 */
struct PlateImageView: View {
    let plate: PlateMetadata
    
    var body: some View {
        AsyncPlateImageView.card(plate: plate)
    }
}

/**
 * Category badge for enhanced metadata
 */
struct CategoryBadge: View {
    let category: PlateCategory
    
    var body: some View {
        Text(category.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

/**
 * Rarity badge for enhanced metadata
 */
struct RarityBadge: View {
    let rarity: PlateRarity
    
    private var badgeColor: Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .veryRare: return .purple
        case .legendary: return .orange
        }
    }
    
    var body: some View {
        Text(rarity.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.1))
            .foregroundColor(badgeColor)
            .cornerRadius(4)
    }
}

// MARK: - Confirmation Step Components

/**
 * Detailed plate information card
 */
struct PlateDetailCard: View {
    let plate: PlateMetadata
    
    var body: some View {
        VStack(spacing: 16) {
            // Plate image
            AsyncPlateImageView.detail(plate: plate)
            
            VStack(spacing: 8) {
                Text(plate.plateTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(plate.state)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Enhanced metadata details
                if plate.hasEnhancedMetadata {
                    VStack(spacing: 6) {
                        if let category = plate.category {
                            DetailRow(label: "Category", value: category.displayName)
                        }
                        
                        if let rarity = plate.rarity {
                            DetailRow(label: "Rarity", value: rarity.displayName)
                        }
                        
                        if let confidence = plate.confidenceScore {
                            DetailRow(label: "Confidence", value: "\(Int(confidence * 100))%")
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * Game context information
 */
struct GameContextCard: View {
    let game: Game
    @EnvironmentObject var gameManager: GameManagerService
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Adding to Game")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                DetailRow(label: "Game", value: gameManager.displayName(for: game))
                DetailRow(label: "Mode", value: game.mode.displayName)
                DetailRow(label: "Current Progress", value: "\(game.plateCount) plates")
                
                if game.mode == .stateCollection {
                    DetailRow(label: "States Collected", value: "\(game.stateCount)/50")
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

/**
 * Warning card for already collected plates
 */
struct WarningCard: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

/**
 * Generic detail row for key-value pairs
 */
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Additional Components

/**
 * Filter sheet for enhanced metadata
 */
struct FilterSheet: View {
    @Binding var selectedCategory: PlateCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Button("All Categories") {
                        selectedCategory = nil
                        dismiss()
                    }
                    .foregroundColor(selectedCategory == nil ? .blue : .primary)
                    
                    ForEach(PlateCategory.allCases, id: \.self) { category in
                        Button(category.displayName) {
                            selectedCategory = category
                            dismiss()
                        }
                        .foregroundColor(selectedCategory == category ? .blue : .primary)
                    }
                }
            }
            .navigationTitle("Filters")
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

/**
 * Empty state for plate selection
 */
struct EmptyPlateSelectionView: View {
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
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * Success overlay for successful plate logging
 */
struct SuccessOverlay: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 4) {
                Text("Plate Logged!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Added to your collection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .onTapGesture {
            onDismiss()
        }
    }
}