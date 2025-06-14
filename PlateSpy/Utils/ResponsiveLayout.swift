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

/**
 * View modifier for responsive grid layouts
 */
struct ResponsiveGridModifier: ViewModifier {
    let portraitColumns: Int
    let landscapeColumns: Int
    let spacing: CGFloat
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .environment(\.responsiveColumns, responsiveColumns(for: geometry.size))
        }
    }
    
    private func responsiveColumns(for size: CGSize) -> [GridItem] {
        let isLandscape = size.width > size.height
        let columnCount = isLandscape ? landscapeColumns : portraitColumns
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}

/**
 * Environment key for responsive columns
 */
private struct ResponsiveColumnsKey: EnvironmentKey {
    static let defaultValue: [GridItem] = Array(repeating: GridItem(.flexible()), count: 2)
}

extension EnvironmentValues {
    var responsiveColumns: [GridItem] {
        get { self[ResponsiveColumnsKey.self] }
        set { self[ResponsiveColumnsKey.self] = newValue }
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
     * Get adaptive grid columns based on screen size
     */
    static func adaptiveGridColumns(
        portraitColumns: Int = 2,
        landscapeColumns: Int = 4,
        spacing: CGFloat = 16
    ) -> [GridItem] {
        // Use a simple heuristic based on screen bounds
        let screenSize = UIScreen.main.bounds.size
        let isLandscape = screenSize.width > screenSize.height
        let columnCount = isLandscape ? landscapeColumns : portraitColumns
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
    
    /**
     * Create responsive grid columns using GeometryReader
     */
    static func responsiveColumns(
        geometry: GeometryProxy,
        portraitColumns: Int = 2,
        landscapeColumns: Int = 4,
        spacing: CGFloat = 16
    ) -> [GridItem] {
        let isLandscape = geometry.size.width > geometry.size.height
        let columnCount = isLandscape ? landscapeColumns : portraitColumns
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
}