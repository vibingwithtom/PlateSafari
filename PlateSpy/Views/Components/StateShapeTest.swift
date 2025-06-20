//
//  StateShapeTest.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/16/25.
//

import SwiftUI
import FeatureShapes
@preconcurrency import GeoJSON

/**
 * Experimental view to test SVG state shapes using FeatureShapes
 * This replaces the current circle-based state representations
 */
struct StateShapeTest: View {
    @State private var features: [Feature] = []
    @State private var loadingError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("State Shape Test")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let error = loadingError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else if !features.isEmpty {
                Text("Loaded \(features.count) states")
                    .foregroundColor(.green)
                
                // Test rendering the states
                GeometryReader { geometry in
                    // Debug info
                    Text("Rect: \(Int(geometry.size.width))x\(Int(geometry.size.height))")
                        .font(.caption)
                        .position(x: 50, y: 20)
                    
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        FeatureShape(feature: feature, projection: SimpleProjection())
                            .fill(testColors[index % testColors.count])
                            .stroke(Color.black, lineWidth: 2)
                        
                        // Add state name labels for debugging
                        Text("State \(index)")
                            .font(.caption)
                            .foregroundColor(.black)
                            .position(x: 50 + CGFloat(index * 60), y: 40)
                    }
                }
                .aspectRatio(2.4, contentMode: .fit)
                .frame(maxHeight: 300)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
            } else {
                ProgressView("Loading states...")
                    .padding()
            }
            
            Button("Load Test Data") {
                loadGeoJSONData()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            loadGeoJSONData()
        }
    }
    
    private let testColors: [Color] = [.blue, .green, .orange, .purple, .red]
    
    private func loadGeoJSONData() {
        guard let url = Bundle.main.url(forResource: "us-states-all", withExtension: "json") else {
            loadingError = "Could not find us-states-all.json file"
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let featureCollection = try JSONDecoder().decode(FeatureCollection.self, from: data)
            features = featureCollection.features
            loadingError = nil
        } catch {
            loadingError = "Failed to decode GeoJSON: \(error.localizedDescription)"
        }
    }
}

/**
 * Simple bounds projection that forces shapes to fill available space
 */
struct SimpleProjection: Projection {
    func project(position: Position, in rect: CGRect) -> CGPoint {
        // US continental bounds - tighter fit
        let lonMin: Double = -125.0  // West coast
        let lonMax: Double = -66.0   // East coast  
        let latMin: Double = 20.0    // Southern tip
        let latMax: Double = 50.0    // Northern border
        
        let normalizedX = (position.longitude - lonMin) / (lonMax - lonMin)
        let normalizedY = 1.0 - (position.latitude - latMin) / (latMax - latMin)
        
        return CGPoint(
            x: rect.minX + normalizedX * rect.width,
            y: rect.minY + normalizedY * rect.height
        )
    }
}

#Preview {
    StateShapeTest()
}