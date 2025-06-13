//
//  CreateGameSheet.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Sheet for creating new games
 * Allows users to select game mode and optionally name their game
 */
struct CreateGameSheet: View {
    @EnvironmentObject var gameManager: GameManagerService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMode: GameMode = .stateCollection
    @State private var gameName: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Game mode selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose Game Mode")
                            .font(.headline)
                        
                        ForEach(GameMode.allCases, id: \.self) { mode in
                            GameModeOption(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                action: { selectedMode = mode }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Game Setup")
                }
                
                Section {
                    // Optional game name
                    TextField("Game Name (Optional)", text: $gameName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } header: {
                    Text("Customization")
                } footer: {
                    Text("Leave blank for automatic naming based on creation date")
                        .font(.caption)
                }
                
                Section {
                    // Current games count info
                    HStack {
                        Text("Active Games")
                        Spacer()
                        Text("\(gameManager.games.count)/5")
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("You can have up to 5 active games at once")
                        .font(.caption)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGame()
                    }
                    .fontWeight(.semibold)
                    .disabled(!gameManager.canCreateNewGame)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    /**
     * Create the game and dismiss the sheet
     */
    private func createGame() {
        let name = gameName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = name.isEmpty ? nil : name
        
        if let _ = gameManager.createGame(mode: selectedMode, name: finalName) {
            dismiss()
        } else {
            errorMessage = "Unable to create game. Maximum of 5 games allowed."
            showingError = true
        }
    }
}

/**
 * Individual game mode selection option
 * Shows mode details and selection state
 */
struct GameModeOption: View {
    let mode: GameMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Mode icon
                Image(systemName: mode == .stateCollection ? "map" : "square.grid.3x3")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateGameSheet()
        .environmentObject(GameManagerService())
}