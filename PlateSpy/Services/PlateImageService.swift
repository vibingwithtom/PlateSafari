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
 * 
 * Features:
 * - Efficient memory caching with automatic cleanup on memory pressure
 * - Handles shared images (like MISSING.png) across multiple states
 * - Falls back gracefully from bundle resources to file system
 * - Optimizes memory usage by sharing common images between plates
 * - Thread-safe asynchronous loading with completion handlers
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
     * 
     * Uses two-tier caching strategy:
     * 1. Plate-specific cache (state-filename combination)
     * 2. Shared cache for common images (filename only)
     * 
     * @param plate The plate metadata containing state and image filename
     * @param completion Callback with loaded UIImage or nil if failed
     */
    func loadImage(for plate: PlateMetadata, completion: @escaping (UIImage?) -> Void) {
        let plateCacheKey = "\(plate.state)-\(plate.plateImage)" as NSString
        let imageCacheKey = plate.plateImage as NSString // Shared cache key for identical images
        
        // Check plate-specific cache first
        if let cachedImage = imageCache.object(forKey: plateCacheKey) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // Check shared image cache for common files like MISSING.png
        if let sharedImage = bundleImageCache.object(forKey: imageCacheKey) {
            // Cache it with plate-specific key too
            imageCache.setObject(sharedImage, forKey: plateCacheKey)
            DispatchQueue.main.async {
                completion(sharedImage)
            }
            return
        }
        
        // Load asynchronously
        processingQueue.async { [weak self] in
            let image = self?.loadImageSync(for: plate)
            
            // Cache the result with both keys
            if let image = image {
                self?.imageCache.setObject(image, forKey: plateCacheKey)
                
                // Cache common images (like MISSING.png) with shared key for efficiency
                if self?.isCommonImage(plate.plateImage) == true {
                    self?.bundleImageCache.setObject(image, forKey: imageCacheKey)
                }
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
        
        // For now, skip external file loading since images aren't in app bundle
        // TODO: Images need to be properly bundled or loaded from server
        print("📷 Image loading from external paths not available on device/simulator")
        
        // Fallback: try bundle path
        guard let bundlePath = Bundle.main.resourcePath else { return nil }
        let imagePath = "\(bundlePath)/SourcePlateImages/\(state)/\(imageName)"
        
        // Try to load from the specific state folder first
        if FileManager.default.fileExists(atPath: imagePath),
           let image = UIImage(contentsOfFile: imagePath) {
            
            let resizedImage = resizeImage(image, targetSize: CGSize(width: 300, height: 150))
            bundleImageCache.setObject(resizedImage, forKey: cacheKey)
            return resizedImage
        }
        
        // If it's a common image and not found in the specific state, try to find it in any state folder
        if isCommonImage(imageName) {
            return loadCommonImageFromAnyState(imageName: imageName, bundlePath: bundlePath, cacheKey: cacheKey)
        }
        
        return nil
    }
    
    /**
     * Load common images (like MISSING.png) from any available state folder
     */
    private func loadCommonImageFromAnyState(imageName: String, bundlePath: String, cacheKey: NSString) -> UIImage? {
        // Try project directory first
        let projectSourcePath = "/Users/raia/XCodeProjects/PlateSpy/SourcePlateImages"
        if FileManager.default.fileExists(atPath: projectSourcePath),
           let image = searchForImageInPath(imageName: imageName, basePath: projectSourcePath, cacheKey: cacheKey) {
            return image
        }
        
        // Fallback to bundle path
        let sourceImagesPath = "\(bundlePath)/SourcePlateImages"
        return searchForImageInPath(imageName: imageName, basePath: sourceImagesPath, cacheKey: cacheKey)
    }
    
    /**
     * Helper method to search for an image in any state subdirectory
     */
    private func searchForImageInPath(imageName: String, basePath: String, cacheKey: NSString) -> UIImage? {
        do {
            let stateDirectories = try FileManager.default.contentsOfDirectory(atPath: basePath)
            
            for stateDir in stateDirectories {
                let imagePath = "\(basePath)/\(stateDir)/\(imageName)"
                
                if FileManager.default.fileExists(atPath: imagePath),
                   let image = UIImage(contentsOfFile: imagePath) {
                    
                    let resizedImage = resizeImage(image, targetSize: CGSize(width: 300, height: 150))
                    bundleImageCache.setObject(resizedImage, forKey: cacheKey)
                    
                    // Also cache with the shared key for future efficiency
                    let sharedKey = imageName as NSString
                    bundleImageCache.setObject(resizedImage, forKey: sharedKey)
                    
                    return resizedImage
                }
            }
        } catch {
            print("⚠️ Error searching for common image \(imageName) in \(basePath): \(error)")
        }
        
        return nil
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
            context.cgContext.addRect(borderRect)
            context.cgContext.strokePath()
            
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
     * Check if an image is commonly reused across states
     * These images should be cached with shared keys for efficiency
     */
    private func isCommonImage(_ imageName: String) -> Bool {
        let commonImages = [
            "MISSING.png",
            "missing.png",
            "Missing.png",
            "standard.jpg",
            "standard-plate.jpg",
            "regular.jpg",
            "disabled.png",
            "antique.gif",
            "moped.gif"
        ]
        return commonImages.contains(imageName)
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