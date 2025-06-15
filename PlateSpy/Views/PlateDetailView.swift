//
//  PlateDetailView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/15/25.
//

import SwiftUI

/**
 * Detailed view for individual license plates
 * Shows large image, metadata, and collection status
 */
struct PlateDetailView: View {
    let plate: PlateMetadata
    let game: Game?
    @EnvironmentObject var gameManager: GameManagerService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCollectionConfirmation = false
    @State private var isCollecting = false
    @State private var showingCollectionSuccess = false
    @State private var showingCollectionError = false
    @State private var errorMessage = ""
    
    var isCollected: Bool {
        guard let game = game else { return false }
        return gameManager.isPlateCollected(
            gameId: game.id,
            state: plate.state,
            plateTitle: plate.plateTitle
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large plate image
                    PlateImageSection(plate: plate)
                    
                    // Plate information
                    PlateInfoSection(plate: plate, isCollected: isCollected)
                    
                    // Enhanced metadata (if available)
                    if plate.hasEnhancedMetadata {
                        EnhancedMetadataSection(plate: plate)
                    }
                    
                    // Image source information (if available)
                    if let source = plate.source, !source.isEmpty {
                        ImageSourceSection(sourceURL: source)
                    }
                    
                    // Collection actions (if game context provided)
                    if let game = game {
                        CollectionActionsSection(
                            plate: plate,
                            game: game,
                            isCollected: isCollected,
                            isCollecting: isCollecting,
                            onCollect: { showingCollectionConfirmation = true }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(plate.plateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Collect Plate", isPresented: $showingCollectionConfirmation) {
                Button("Collect", action: collectPlate)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Add \"\(plate.plateTitle)\" from \(USStatePositions.fullName(for: plate.state) ?? plate.state) to your collection?")
            }
            .alert("Error", isPresented: $showingCollectionError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if showingCollectionSuccess {
                        PlateCollectionSuccessOverlay {
                            dismiss()
                        }
                    }
                }
            )
        }
    }
    
    private func collectPlate() {
        guard let game = game else { return }
        
        isCollecting = true
        
        // Check if already collected
        if gameManager.isPlateCollected(gameId: game.id, state: plate.state, plateTitle: plate.plateTitle) {
            errorMessage = "This plate has already been collected in this game."
            showingCollectionError = true
            isCollecting = false
            return
        }
        
        // Collect the plate
        let success = gameManager.collectPlate(gameId: game.id, metadata: plate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isCollecting = false
            
            if success {
                showingCollectionSuccess = true
                // Auto-dismiss after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if showingCollectionSuccess {
                        dismiss()
                    }
                }
            } else {
                errorMessage = "Failed to collect plate. Please try again."
                showingCollectionError = true
            }
        }
    }
}

/**
 * Large plate image section
 */
struct PlateImageSection: View {
    let plate: PlateMetadata
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncPlateImageView(plate: plate, cornerRadius: 16)
                .aspectRatio(2, contentMode: .fit)
                .frame(maxHeight: 200)
                .shadow(radius: 8)
            
            Text("\(USStatePositions.fullName(for: plate.state) ?? plate.state) License Plate")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

/**
 * Basic plate information section
 */
struct PlateInfoSection: View {
    let plate: PlateMetadata
    let isCollected: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Plate title and collection status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plate.plateTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(USStatePositions.fullName(for: plate.state) ?? plate.state)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isCollected {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Collected")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Divider()
        }
    }
}

/**
 * Enhanced metadata section (categories, rarity, etc.)
 */
struct EnhancedMetadataSection: View {
    let plate: PlateMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Category and rarity badges
                if plate.category != nil || plate.rarity != nil {
                    HStack {
                        if let category = plate.category {
                            CategoryBadge(category: category)
                        }
                        
                        if let rarity = plate.rarity {
                            RarityBadge(rarity: rarity)
                                .padding(.leading, plate.category != nil ? 8 : 0)
                        }
                        
                        Spacer()
                    }
                }
                
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

/**
 * Individual metadata row
 */
struct MetadataRow: View {
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

/**
 * Image source section with clickable link
 */
struct ImageSourceSection: View {
    let sourceURL: String
    @State private var showingWebView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Image Source")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { showingWebView = true }) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                    
                    Text("View Original Source")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingWebView) {
            ImageSourceWebView(url: sourceURL)
        }
    }
}

/**
 * Web view for displaying image source
 */
struct ImageSourceWebView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            WebView(url: URL(string: url))
                .navigationTitle("Image Source")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

/**
 * UIKit WebView wrapper for SwiftUI
 */
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

/**
 * Collection actions section
 */
struct CollectionActionsSection: View {
    let plate: PlateMetadata
    let game: Game
    let isCollected: Bool
    let isCollecting: Bool
    let onCollect: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if isCollected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Already in your collection")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                Button(action: onCollect) {
                    HStack {
                        if isCollecting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        
                        Text(isCollecting ? "Collecting..." : "Add to Collection")
                            .fontWeight(.semibold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isCollecting)
            }
        }
    }
}

/**
 * Success overlay for plate collection
 */
struct PlateCollectionSuccessOverlay: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Plate Collected!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
        .onTapGesture {
            onDismiss()
        }
    }
}

#Preview {
    PlateDetailView(
        plate: PlateMetadata(
            state: "NY",
            plateTitle: "Empire Gold",
            plateImage: "ny_empire_gold.jpg"
        ),
        game: Game(mode: .stateCollection, name: "Test Game")
    )
    .environmentObject(GameManagerService())
}