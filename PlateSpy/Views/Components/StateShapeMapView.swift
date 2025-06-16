//
//  StateShapeMapView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/16/25.
//

import SwiftUI
import FeatureShapes
@preconcurrency import GeoJSON

/**
 * Interactive US map using actual state boundary shapes
 * Replaces circle-based visualization with geographic state outlines
 */
struct StateShapeMapView: View {
    let game: Game
    let compactMode: Bool
    let showHeader: Bool
    @State private var features: [Feature] = []
    @State private var loadingError: String?
    @Binding var selectedState: String?
    @State private var showingFullMap = false
    
    init(game: Game, compactMode: Bool = true, showHeader: Bool = true, selectedState: Binding<String?> = .constant(nil)) {
        self.game = game
        self.compactMode = compactMode
        self.showHeader = showHeader
        self._selectedState = selectedState
    }
    
    var body: some View {
        VStack(spacing: compactMode ? 8 : 16) {
            if compactMode && showHeader {
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
            }
            
            // Map content
            if let error = loadingError {
                Text("Map Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            } else if !features.isEmpty {
                // Actual state shapes map with inset Alaska and Hawaii
                GeometryReader { geometry in
                    ZStack {
                        // Continental US (including DC)
                        ForEach(continentalFeatures, id: \.id) { feature in
                            let stateCode: String = feature.properties?["stusps"] ?? ""
                            let progress = game.stateProgress[stateCode] ?? 0
                            let isSelected = selectedState == stateCode
                            
                            FeatureShape(feature: feature, projection: ContinentalUSProjection())
                                .fill(stateColor(for: progress, gameMode: game.mode))
                                .stroke(
                                    isSelected ? Color.orange : Color.black,
                                    lineWidth: isSelected ? 2 : 0.5
                                )
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedState = selectedState == stateCode ? nil : stateCode
                                    }
                                }
                        }
                        
                        // Alaska inset (bottom left)
                        if let alaskaFeature = features.first(where: { $0.properties?["stusps"] == "AK" }) {
                            let progress = game.stateProgress["AK"] ?? 0
                            let isSelected = selectedState == "AK"
                            
                            FeatureShape(feature: alaskaFeature, projection: AlaskaProjection())
                                .fill(stateColor(for: progress, gameMode: game.mode))
                                .stroke(
                                    isSelected ? Color.orange : Color.black,
                                    lineWidth: isSelected ? 2 : 0.5
                                )
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedState = selectedState == "AK" ? nil : "AK"
                                    }
                                }
                                .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.25)
                                .position(x: geometry.size.width * 0.12, y: geometry.size.height * 0.85)
                        }
                        
                        // Hawaii inset (bottom left, below Alaska)
                        if let hawaiiFeature = features.first(where: { $0.properties?["stusps"] == "HI" }) {
                            let progress = game.stateProgress["HI"] ?? 0
                            let isSelected = selectedState == "HI"
                            
                            FeatureShape(feature: hawaiiFeature, projection: HawaiiProjection())
                                .fill(stateColor(for: progress, gameMode: game.mode))
                                .stroke(
                                    isSelected ? Color.orange : Color.black,
                                    lineWidth: isSelected ? 2 : 0.5
                                )
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedState = selectedState == "HI" ? nil : "HI"
                                    }
                                }
                                .frame(width: geometry.size.width * 0.12, height: geometry.size.height * 0.15)
                                .position(x: geometry.size.width * 0.12, y: geometry.size.height * 0.65)
                        }
                    }
                }
                .aspectRatio(2.4, contentMode: .fit)
                .frame(maxHeight: compactMode ? 150 : 300)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                // Loading state
                ProgressView("Loading map...")
                    .frame(height: compactMode ? 150 : 300)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            if !compactMode {
                MapLegend(gameMode: game.mode)
                StateProgressTable(game: game, selectedState: selectedState)
            }
        }
        .onAppear {
            loadUSStatesData()
        }
        .sheet(isPresented: $showingFullMap) {
            FullMapView(game: game)
        }
    }
    
    private var continentalFeatures: [Feature] {
        features.filter { feature in
            guard let stateCode: String = feature.properties?["stusps"] else { return false }
            return stateCode != "AK" && stateCode != "HI"
        }
    }
    
    private func stateColor(for progress: Int, gameMode: GameMode) -> Color {
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
    
    private func loadUSStatesData() {
        // Load complete US states data (all 50 states + DC + PR)
        guard let url = Bundle.main.url(forResource: "us-states-all", withExtension: "json") else {
            loadingError = "Could not find state boundary data"
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let featureCollection = try JSONDecoder().decode(FeatureCollection.self, from: data)
            features = featureCollection.features
            loadingError = nil
        } catch {
            loadingError = "Failed to load state data: \(error.localizedDescription)"
        }
    }
}

/**
 * Continental US projection (48 states + DC)
 */
struct ContinentalUSProjection: Projection {
    func project(position: Position, in rect: CGRect) -> CGPoint {
        // Continental US bounds (excludes Alaska and Hawaii)
        let lonMin: Double = -125.0  // West coast
        let lonMax: Double = -66.0   // East coast  
        let latMin: Double = 20.0    // Southern tip (Florida Keys)
        let latMax: Double = 50.0    // Northern border (Canada)
        
        let normalizedX = (position.longitude - lonMin) / (lonMax - lonMin)
        let normalizedY = 1.0 - (position.latitude - latMin) / (latMax - latMin)
        
        return CGPoint(
            x: rect.minX + normalizedX * rect.width,
            y: rect.minY + normalizedY * rect.height
        )
    }
}

/**
 * Alaska-specific projection for inset map
 */
struct AlaskaProjection: Projection {
    func project(position: Position, in rect: CGRect) -> CGPoint {
        // Alaska bounds
        let lonMin: Double = -180.0  // Western Aleutians
        let lonMax: Double = -130.0  // Eastern border
        let latMin: Double = 54.0    // Southern border
        let latMax: Double = 72.0    // Northern border
        
        let normalizedX = (position.longitude - lonMin) / (lonMax - lonMin)
        let normalizedY = 1.0 - (position.latitude - latMin) / (latMax - latMin)
        
        return CGPoint(
            x: rect.minX + normalizedX * rect.width,
            y: rect.minY + normalizedY * rect.height
        )
    }
}

/**
 * Hawaii-specific projection for inset map
 */
struct HawaiiProjection: Projection {
    func project(position: Position, in rect: CGRect) -> CGPoint {
        // Hawaii bounds
        let lonMin: Double = -180.0  // Western islands
        let lonMax: Double = -154.0  // Eastern islands
        let latMin: Double = 18.0    // Southern islands
        let latMax: Double = 29.0    // Northern extent
        
        let normalizedX = (position.longitude - lonMin) / (lonMax - lonMin)
        let normalizedY = 1.0 - (position.latitude - latMin) / (latMax - latMin)
        
        return CGPoint(
            x: rect.minX + normalizedX * rect.width,
            y: rect.minY + normalizedY * rect.height
        )
    }
}

#Preview {
    @Previewable @State var selectedState: String? = nil
    
    return VStack(spacing: 20) {
        // Compact mode (for cards)
        StateShapeMapView(game: Game(mode: .stateCollection, name: "State Challenge"), compactMode: true, selectedState: $selectedState)
            .padding()
        
        // Full mode
        StateShapeMapView(game: Game(mode: .plateCollection, name: "Plate Collection"), compactMode: false, selectedState: $selectedState)
            .padding()
    }
    .environmentObject(GameManagerService())
}