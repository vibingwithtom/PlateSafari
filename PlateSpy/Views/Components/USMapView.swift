//
//  USMapView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Interactive US map visualization for game progress
 * Shows state-by-state collection progress with color coding
 */
struct USMapView: View {
    let game: Game
    let compactMode: Bool
    @State private var selectedState: String?
    @State private var showingFullMap = false
    
    init(game: Game, compactMode: Bool = true) {
        self.game = game
        self.compactMode = compactMode
    }
    
    var body: some View {
        VStack(spacing: compactMode ? 8 : 16) {
            if compactMode {
                // Compact header with "View Full Map" button
                HStack {
                    Text("Collection Map")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("View Full Map") {
                        showingFullMap = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                MapHeader(game: game)
            }
            
            // Simplified US map using positioned state elements
            GeometryReader { geometry in
                ForEach(USStatePositions.allStates, id: \.abbreviation) { stateData in
                    StateMapElement(
                        state: stateData,
                        progress: game.stateProgress[stateData.abbreviation] ?? 0,
                        gameMode: game.mode,
                        isSelected: selectedState == stateData.abbreviation,
                        size: compactMode ? .compact : .standard
                    )
                    .position(
                        x: geometry.size.width * stateData.x,
                        y: geometry.size.height * stateData.y
                    )
                    .onTapGesture {
                        selectedState = selectedState == stateData.abbreviation ? nil : stateData.abbreviation
                    }
                }
            }
            .aspectRatio(2.4, contentMode: .fit)
            .frame(maxHeight: compactMode ? 150 : 300)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            if !compactMode {
                MapLegend(gameMode: game.mode)
                StateProgressTable(game: game, selectedState: selectedState)
            }
        }
        .sheet(isPresented: $showingFullMap) {
            FullMapView(game: game)
        }
    }
}

/**
 * Individual state element on the map
 */
struct StateMapElement: View {
    let state: USStatePosition
    let progress: Int
    let gameMode: GameMode
    let isSelected: Bool
    let size: StateElementSize
    
    enum StateElementSize {
        case compact, standard
        
        var dimension: CGFloat {
            switch self {
            case .compact: return 8
            case .standard: return 12
            }
        }
    }
    
    private var stateColor: Color {
        switch gameMode {
        case .stateCollection:
            // Binary: collected (blue) vs not collected (gray)
            return progress > 0 ? .blue : Color(.systemGray4)
        case .plateCollection:
            // Intensity based on plate count
            if progress == 0 { return Color(.systemGray4) }
            else if progress <= 2 { return .green.opacity(0.6) }
            else if progress <= 5 { return .green }
            else if progress <= 10 { return .blue }
            else { return .purple }
        }
    }
    
    var body: some View {
        Circle()
            .fill(stateColor)
            .frame(width: size.dimension, height: size.dimension)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/**
 * Map header with title and summary stats
 */
struct MapHeader: View {
    let game: Game
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Collection Map")
                    .font(.headline)
                
                Text("\(game.stateCount) states • \(game.plateCount) plates")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f%% Complete", completionPercentage))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text(game.mode.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var completionPercentage: Double {
        switch game.mode {
        case .stateCollection:
            return Double(game.stateCount) / 51.0 * 100.0
        case .plateCollection:
            return min(Double(game.plateCount) / 200.0 * 100.0, 100.0)
        }
    }
}

/**
 * Map legend showing color meanings
 */
struct MapLegend: View {
    let gameMode: GameMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 16) {
                switch gameMode {
                case .stateCollection:
                    LegendItem(color: .blue, label: "Collected")
                    LegendItem(color: Color(.systemGray4), label: "Not Collected")
                case .plateCollection:
                    LegendItem(color: .green.opacity(0.6), label: "1-2 plates")
                    LegendItem(color: .green, label: "3-5 plates")
                    LegendItem(color: .blue, label: "6-10 plates")
                    LegendItem(color: .purple, label: "10+ plates")
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}

/**
 * Individual legend item
 */
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/**
 * State progress data table
 */
struct StateProgressTable: View {
    let game: Game
    let selectedState: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("State Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(sortedStates.count) states with plates")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if sortedStates.isEmpty {
                Text("No plates collected yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(sortedStates.prefix(10), id: \.key) { state, count in
                        StateProgressRow(
                            state: state,
                            count: count,
                            isSelected: selectedState == state
                        )
                    }
                    
                    if sortedStates.count > 10 {
                        Text("... and \(sortedStates.count - 10) more states")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
    
    private var sortedStates: [(key: String, value: Int)] {
        game.stateProgress.sorted { $0.value > $1.value }
    }
}

/**
 * Individual state progress row
 */
struct StateProgressRow: View {
    let state: String
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(USStatePositions.fullName(for: state) ?? state)
                .font(.subheadline)
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundColor(isSelected ? .blue : .primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 2)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

/**
 * US state positioning data for map layout
 * Simplified representation using approximate relative positions
 */
struct USStatePosition {
    let abbreviation: String
    let name: String
    let x: Double  // Relative position (0.0 to 1.0)
    let y: Double  // Relative position (0.0 to 1.0)
}

struct USStatePositions {
    static let allStates: [USStatePosition] = [
        // West Coast
        USStatePosition(abbreviation: "WA", name: "Washington", x: 0.15, y: 0.1),
        USStatePosition(abbreviation: "OR", name: "Oregon", x: 0.12, y: 0.25),
        USStatePosition(abbreviation: "CA", name: "California", x: 0.08, y: 0.4),
        USStatePosition(abbreviation: "NV", name: "Nevada", x: 0.18, y: 0.35),
        
        // Mountain West
        USStatePosition(abbreviation: "ID", name: "Idaho", x: 0.25, y: 0.15),
        USStatePosition(abbreviation: "MT", name: "Montana", x: 0.35, y: 0.1),
        USStatePosition(abbreviation: "WY", name: "Wyoming", x: 0.35, y: 0.25),
        USStatePosition(abbreviation: "UT", name: "Utah", x: 0.28, y: 0.35),
        USStatePosition(abbreviation: "CO", name: "Colorado", x: 0.4, y: 0.4),
        USStatePosition(abbreviation: "AZ", name: "Arizona", x: 0.28, y: 0.55),
        USStatePosition(abbreviation: "NM", name: "New Mexico", x: 0.38, y: 0.55),
        
        // Plains States
        USStatePosition(abbreviation: "ND", name: "North Dakota", x: 0.5, y: 0.1),
        USStatePosition(abbreviation: "SD", name: "South Dakota", x: 0.5, y: 0.25),
        USStatePosition(abbreviation: "NE", name: "Nebraska", x: 0.5, y: 0.35),
        USStatePosition(abbreviation: "KS", name: "Kansas", x: 0.5, y: 0.45),
        USStatePosition(abbreviation: "OK", name: "Oklahoma", x: 0.52, y: 0.55),
        USStatePosition(abbreviation: "TX", name: "Texas", x: 0.48, y: 0.7),
        
        // Great Lakes
        USStatePosition(abbreviation: "MN", name: "Minnesota", x: 0.6, y: 0.15),
        USStatePosition(abbreviation: "IA", name: "Iowa", x: 0.6, y: 0.3),
        USStatePosition(abbreviation: "MO", name: "Missouri", x: 0.6, y: 0.45),
        USStatePosition(abbreviation: "AR", name: "Arkansas", x: 0.6, y: 0.6),
        USStatePosition(abbreviation: "LA", name: "Louisiana", x: 0.6, y: 0.75),
        
        USStatePosition(abbreviation: "WI", name: "Wisconsin", x: 0.7, y: 0.2),
        USStatePosition(abbreviation: "IL", name: "Illinois", x: 0.68, y: 0.35),
        USStatePosition(abbreviation: "MS", name: "Mississippi", x: 0.68, y: 0.65),
        
        USStatePosition(abbreviation: "MI", name: "Michigan", x: 0.75, y: 0.25),
        USStatePosition(abbreviation: "IN", name: "Indiana", x: 0.75, y: 0.35),
        USStatePosition(abbreviation: "KY", name: "Kentucky", x: 0.72, y: 0.45),
        USStatePosition(abbreviation: "TN", name: "Tennessee", x: 0.72, y: 0.5),
        USStatePosition(abbreviation: "AL", name: "Alabama", x: 0.72, y: 0.6),
        
        USStatePosition(abbreviation: "OH", name: "Ohio", x: 0.8, y: 0.35),
        USStatePosition(abbreviation: "WV", name: "West Virginia", x: 0.8, y: 0.45),
        USStatePosition(abbreviation: "GA", name: "Georgia", x: 0.8, y: 0.6),
        USStatePosition(abbreviation: "FL", name: "Florida", x: 0.85, y: 0.75),
        
        // East Coast
        USStatePosition(abbreviation: "PA", name: "Pennsylvania", x: 0.85, y: 0.35),
        USStatePosition(abbreviation: "NY", name: "New York", x: 0.85, y: 0.25),
        USStatePosition(abbreviation: "VT", name: "Vermont", x: 0.9, y: 0.2),
        USStatePosition(abbreviation: "NH", name: "New Hampshire", x: 0.92, y: 0.22),
        USStatePosition(abbreviation: "ME", name: "Maine", x: 0.95, y: 0.15),
        USStatePosition(abbreviation: "MA", name: "Massachusetts", x: 0.92, y: 0.28),
        USStatePosition(abbreviation: "RI", name: "Rhode Island", x: 0.93, y: 0.32),
        USStatePosition(abbreviation: "CT", name: "Connecticut", x: 0.9, y: 0.32),
        USStatePosition(abbreviation: "NJ", name: "New Jersey", x: 0.88, y: 0.38),
        USStatePosition(abbreviation: "DE", name: "Delaware", x: 0.87, y: 0.42),
        USStatePosition(abbreviation: "MD", name: "Maryland", x: 0.85, y: 0.42),
        USStatePosition(abbreviation: "VA", name: "Virginia", x: 0.82, y: 0.48),
        USStatePosition(abbreviation: "NC", name: "North Carolina", x: 0.82, y: 0.52),
        USStatePosition(abbreviation: "SC", name: "South Carolina", x: 0.82, y: 0.58),
        
        // Non-contiguous
        USStatePosition(abbreviation: "AK", name: "Alaska", x: 0.15, y: 0.8),
        USStatePosition(abbreviation: "HI", name: "Hawaii", x: 0.25, y: 0.85),
        
        // DC
        USStatePosition(abbreviation: "DC", name: "District of Columbia", x: 0.86, y: 0.44),
    ]
    
    static func fullName(for abbreviation: String) -> String? {
        return allStates.first { $0.abbreviation == abbreviation }?.name
    }
    
    static func position(for abbreviation: String) -> USStatePosition? {
        return allStates.first { $0.abbreviation == abbreviation }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Compact mode (for cards)
        USMapView(game: Game(mode: .stateCollection, name: "State Challenge"), compactMode: true)
            .padding()
        
        // Full mode
        USMapView(game: Game(mode: .plateCollection, name: "Plate Collection"), compactMode: false)
            .padding()
    }
    .environmentObject(GameManagerService())
}