//
//  ResponsiveLayout.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/14/25.
//

import SwiftUI

/**
 * Responsive layout utilities for landscape orientation support
 * Provides adaptive grid columns and layout helpers
 */
extension View {
    /**
     * Creates responsive grid columns based on screen width
     * Returns appropriate column count for current device orientation
     */
    func responsiveGridColumns(
        minimumWidth: CGFloat = 160,
        spacing: CGFloat = 16,
        maxColumns: Int = 6
    ) -> [GridItem] {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - (spacing * 2) // Account for padding
        let columnsToFit = Int(availableWidth / (minimumWidth + spacing))
        let columnCount = min(max(columnsToFit, 1), maxColumns)
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}

/**
 * Responsive layout helpers for different screen sizes
 */
struct ResponsiveLayout {
    /**
     * Determines optimal grid column count based on screen width
     */
    static func gridColumns(
        for width: CGFloat,
        minimumItemWidth: CGFloat = 160,
        spacing: CGFloat = 16,
        maxColumns: Int = 6
    ) -> Int {
        let availableWidth = width - (spacing * 2)
        let columnsToFit = Int(availableWidth / (minimumItemWidth + spacing))
        return min(max(columnsToFit, 1), maxColumns)
    }
    
    /**
     * Check if device is in landscape orientation
     */
    static var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape || 
        UIScreen.main.bounds.width > UIScreen.main.bounds.height
    }
    
    /**
     * Get adaptive grid columns for current orientation
     */
    static func adaptiveGridColumns(
        portraitColumns: Int = 2,
        landscapeColumns: Int = 4,
        spacing: CGFloat = 16
    ) -> [GridItem] {
        let columnCount = isLandscape ? landscapeColumns : portraitColumns
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}