//
//  PlateImageService.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI
import UIKit

/**
 * Service for loading and caching license plate images
 * Handles both bundle resources and file system images efficiently
 */
class PlateImageService: ObservableObject {
    static let shared = PlateImageService()
    
    private let imageCache = NSCache<NSString, UIImage>()
    private let bundleImageCache = NSCache<NSString, UIImage>()
    private let processingQueue = DispatchQueue(label: "plate.image.processing", qos: .userInitiated)
    
    private init() {
        // Configure cache limits
        imageCache.countLimit = 200 // Cache up to 200 images
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        bundleImageCache.countLimit = 100
        bundleImageCache.totalCostLimit = 25 * 1024 * 1024 // 25MB for bundle images
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     * Load image for a plate metadata object
     * Returns cached image immediately if available, otherwise loads asynchronously
     */
    func loadImage(for plate: PlateMetadata, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = "\(plate.state)-\(plate.plateImage)" as NSString
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // Load asynchronously
        processingQueue.async { [weak self] in
            let image = self?.loadImageSync(for: plate)
            
            // Cache the result
            if let image = image {
                self?.imageCache.setObject(image, forKey: cacheKey)
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    /**
     * Synchronous image loading for internal use
     */
    private func loadImageSync(for plate: PlateMetadata) -> UIImage? {
        // Try bundle resources first (for development)
        if let bundleImage = loadFromBundle(state: plate.state, imageName: plate.plateImage) {
            return bundleImage
        }
        
        // Try file system (for production)
        if let fileImage = loadFromFileSystem(state: plate.state, imageName: plate.plateImage) {
            return fileImage
        }
        
        // Generate placeholder if no image found
        return generatePlaceholder(for: plate)
    }
    
    /**
     * Load image from app bundle
     */
    private func loadFromBundle(state: String, imageName: String) -> UIImage? {
        let cacheKey = "bundle-\(state)-\(imageName)" as NSString
        
        // Check bundle cache
        if let cachedImage = bundleImageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Try to load from bundle
        let resourceName = imageName.replacingOccurrences(of: "\\.[^.]*$", with: "", options: .regularExpression)
        let pathExtension = (imageName as NSString).pathExtension
        
        guard let imagePath = Bundle.main.path(forResource: "SourcePlateImages/\(state)/\(resourceName)", ofType: pathExtension),
              let image = UIImage(contentsOfFile: imagePath) else {
            return nil
        }
        
        // Resize image for better performance
        let resizedImage = resizeImage(image, targetSize: CGSize(width: 300, height: 150))
        bundleImageCache.setObject(resizedImage, forKey: cacheKey)
        
        return resizedImage
    }
    
    /**
     * Load image from file system
     */
    private func loadFromFileSystem(state: String, imageName: String) -> UIImage? {
        // Construct file path
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let documentsPath = documentsPath else { return nil }
        
        let imagePath = documentsPath
            .appendingPathComponent("SourcePlateImages")
            .appendingPathComponent(state)
            .appendingPathComponent(imageName)
        
        guard FileManager.default.fileExists(atPath: imagePath.path),
              let image = UIImage(contentsOfFile: imagePath.path) else {
            return nil
        }
        
        // Resize image for better performance
        return resizeImage(image, targetSize: CGSize(width: 300, height: 150))
    }
    
    /**
     * Generate a placeholder image for plates without images
     */
    private func generatePlaceholder(for plate: PlateMetadata) -> UIImage {
        let size = CGSize(width: 300, height: 150)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.systemGray5.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Border
            UIColor.systemGray4.setStroke()
            let borderRect = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            context.cgContext.setLineWidth(2)
            context.cgContext.stroke(borderRect)
            
            // State text
            let stateText = plate.state
            let stateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            let stateSize = stateText.size(withAttributes: stateAttributes)
            let stateRect = CGRect(
                x: (size.width - stateSize.width) / 2,
                y: size.height * 0.25 - stateSize.height / 2,
                width: stateSize.width,
                height: stateSize.height
            )
            stateText.draw(in: stateRect, withAttributes: stateAttributes)
            
            // Title text (truncated if too long)
            let titleText = plate.plateTitle.count > 20 ? String(plate.plateTitle.prefix(17)) + "..." : plate.plateTitle
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let titleSize = titleText.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: size.height * 0.75 - titleSize.height / 2,
                width: titleSize.width,
                height: titleSize.height
            )
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
        }
    }
    
    /**
     * Resize image to target size while maintaining aspect ratio
     */
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /**
     * Clear image cache on memory pressure
     */
    @objc private func clearCache() {
        imageCache.removeAllObjects()
        bundleImageCache.removeAllObjects()
        print("🧹 Cleared plate image cache due to memory warning")
    }
    
    /**
     * Preload images for a collection of plates
     * Useful for improving perceived performance
     */
    func preloadImages(for plates: [PlateMetadata], maxConcurrent: Int = 5) {
        let semaphore = DispatchSemaphore(value: maxConcurrent)
        
        for plate in plates.prefix(20) { // Limit preloading to first 20 plates
            processingQueue.async { [weak self] in
                semaphore.wait()
                defer { semaphore.signal() }
                
                self?.loadImage(for: plate) { _ in
                    // Image loaded and cached
                }
            }
        }
    }
    
    /**
     * Get cache statistics for debugging
     */
    var cacheStats: (imageCount: Int, bundleCount: Int, memoryUsage: String) {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .memory
        
        let memoryUsage = formatter.string(fromByteCount: Int64(imageCache.totalCostLimit))
        
        return (
            imageCount: imageCache.countLimit,
            bundleCount: bundleImageCache.countLimit,
            memoryUsage: memoryUsage
        )
    }
}