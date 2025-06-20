//
//  LaunchScreenView.swift
//  PlateSafari
//
//  Created by Claude Code on 6/17/25.
//

import SwiftUI

/**
 * Custom launch screen for Plate Safari
 * Provides branded loading experience with app icon and name
 */
struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // App icon with animation
                VStack(spacing: 16) {
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        
                        // App icon
                        Image(systemName: "car.rear.and.tire.marks")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.blue)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    
                    // App title with fade-in animation
                    if showTitle {
                        VStack(spacing: 8) {
                            Text("Plate Safari")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("License Plate Collection Game")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeOut(duration: 0.8), value: showTitle)
                    }
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    
                    Text("Loading plate data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(isAnimating ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
        .onAppear {
            // Start animations
            isAnimating = true
            
            // Show title after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showTitle = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}