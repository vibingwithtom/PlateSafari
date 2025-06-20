//
//  AsyncPlateImageView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Async image view specifically designed for license plate images
 * Handles loading states, caching, and provides consistent placeholder experience
 */
struct AsyncPlateImageView: View {
    let plate: PlateMetadata
    let cornerRadius: CGFloat
    
    @StateObject private var imageLoader = PlateImageLoader()
    
    init(plate: PlateMetadata, cornerRadius: CGFloat = 8) {
        self.plate = plate
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if imageLoader.isLoading {
                LoadingPlaceholder(plate: plate)
            } else {
                ErrorPlaceholder(plate: plate)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            imageLoader.loadImage(for: plate)
        }
        .onChange(of: plate.id) { _ in
            imageLoader.loadImage(for: plate)
        }
    }
}

/**
 * Observable image loader for individual plates
 * Manages loading state and integrates with PlateImageService
 */
class PlateImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var currentPlate: PlateMetadata?
    private let imageService = PlateImageService.shared
    
    /**
     * Load image for a specific plate
     */
    func loadImage(for plate: PlateMetadata) {
        // Don't reload if it's the same plate
        guard currentPlate?.id != plate.id else { return }
        
        currentPlate = plate
        isLoading = true
        image = nil
        
        imageService.loadImage(for: plate) { [weak self] loadedImage in
            DispatchQueue.main.async {
                // Only update if this is still the current plate
                if self?.currentPlate?.id == plate.id {
                    self?.image = loadedImage
                    self?.isLoading = false
                }
            }
        }
    }
}

/**
 * Loading placeholder while image is being fetched
 */
struct LoadingPlaceholder: View {
    let plate: PlateMetadata
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // Animated loading indicator
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                
                // State text
                Text(plate.state)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                // Loading text
                Text("Loading...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/**
 * Error placeholder when image fails to load
 */
struct ErrorPlaceholder: View {
    let plate: PlateMetadata
    
    var body: some View {
        ZStack {
            // Background with subtle pattern
            Rectangle()
                .fill(Color(.systemGray6))
                .overlay(
                    // Subtle diagonal pattern
                    Path { path in
                        let spacing: CGFloat = 20
                        let width: CGFloat = 300
                        let height: CGFloat = 150
                        
                        for i in stride(from: -height, through: width + height, by: spacing) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i + height, y: height))
                        }
                    }
                    .stroke(Color(.systemGray5), lineWidth: 1)
                    .opacity(0.3)
                )
            
            VStack(spacing: 6) {
                // State badge
                Text(plate.state)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(6)
                
                // Plate icon
                Image(systemName: "car.rear")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                // Plate title (truncated)
                Text(plate.plateTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
                
                // Enhanced metadata indicator
                if plate.hasEnhancedMetadata {
                    HStack(spacing: 4) {
                        if let category = plate.category {
                            Text(category.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }
                        
                        if let rarity = plate.rarity, rarity != .common {
                            RarityIndicator(rarity: rarity)
                        }
                    }
                }
                
                // Confidence score if available
                if let confidence = plate.confidenceScore {
                    Text("\(Int(confidence * 100))% match")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
        }
    }
}

/**
 * Rarity indicator with appropriate styling
 */
struct RarityIndicator: View {
    let rarity: PlateRarity
    
    private var rarityColor: Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .veryRare: return .purple
        case .legendary: return .orange
        }
    }
    
    private var rarityIcon: String {
        switch rarity {
        case .common: return "circle"
        case .uncommon: return "circle.fill"
        case .rare: return "diamond"
        case .veryRare: return "diamond.fill"
        case .legendary: return "star.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: rarityIcon)
                .font(.caption2)
                .foregroundColor(rarityColor)
            
            Text(rarity.displayName)
                .font(.caption2)
                .foregroundColor(rarityColor)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(rarityColor.opacity(0.1))
        .cornerRadius(3)
    }
}

/**
 * Convenience view for common use cases
 */
extension AsyncPlateImageView {
    /**
     * Standard size for card views
     */
    static func card(plate: PlateMetadata) -> some View {
        AsyncPlateImageView(plate: plate, cornerRadius: 8)
            .aspectRatio(2, contentMode: .fit)
    }
    
    /**
     * Large size for detail views
     */
    static func detail(plate: PlateMetadata) -> some View {
        AsyncPlateImageView(plate: plate, cornerRadius: 12)
            .aspectRatio(2, contentMode: .fit)
            .frame(maxHeight: 200)
    }
    
    /**
     * Small thumbnail size
     */
    static func thumbnail(plate: PlateMetadata) -> some View {
        AsyncPlateImageView(plate: plate, cornerRadius: 6)
            .aspectRatio(2, contentMode: .fit)
            .frame(height: 40)
    }
}

#Preview {
    VStack(spacing: 20) {
        AsyncPlateImageView.card(plate: PlateMetadata(
            state: "CA",
            plateTitle: "California Classic",
            plateImage: "classic.png"
        ))
        
        AsyncPlateImageView.detail(plate: PlateMetadata(
            state: "TX", 
            plateTitle: "Texas Longhorn",
            plateImage: "longhorn.png",
            colorBackground: "blue",
            textColor: "white",
            visualElements: "graphic",
            category: "university",
            rarity: "rare",
            layoutStyle: "modern",
            confidenceScore: 0.89,
            notes: "High confidence match",
            source: "manual"
        ))
        
        AsyncPlateImageView.thumbnail(plate: PlateMetadata(
            state: "FL",
            plateTitle: "Florida Sunshine",
            plateImage: "sunshine.png"
        ))
    }
    .padding()
}