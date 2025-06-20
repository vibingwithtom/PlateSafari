# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
```bash
# Build for iOS simulator (use available simulator)
xcodebuild -scheme PlateSpy -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build (when having asset bundle issues)
xcodebuild -scheme PlateSpy -destination 'platform=iOS Simulator,name=iPhone 16' clean build

# Run in iOS simulator (open Xcode and run manually)
open PlateSpy.xcodeproj

# Note: Available simulators can be found with:
# xcodebuild -scheme PlateSpy -showdestinations
```

## Architecture Overview

PlateSpy is a SwiftUI iOS app for collecting license plate images in a gamified experience. The app manages a database of ~8,291 license plates with ~7,880 images from all US states, supporting two collection modes.

### Core Architecture

**Service Layer Pattern**: Two main services injected as environment objects:
- `PlateDataService`: Manages CSV-based plate metadata with enhanced classifications
- `GameManagerService`: Handles multiple simultaneous games (max 5) with UserDefaults persistence

**Data Flow**: App → Services → Views via `@EnvironmentObject` injection from `PlateSpyApp.swift`

### Key Models

**PlateMetadata**: Dual-format support
- Basic: state, plateTitle, plateImage (backward compatibility)
- Enhanced: adds category, rarity, confidence scores, visual classifications

**Game**: Supports two collection modes
- State Collection: One plate per state (traditional 50-state challenge)
- Plate Collection: Unlimited unique plate collection
- Uses Set<CollectedPlate> for efficient duplicate prevention

**GameMode**: Enum with display names, descriptions, and theoretical max completion values

### Data Management

**CSV Loading Strategy**: 
- Attempts enhanced format (`plate_metadata_enhanced.csv`) first
- Falls back to basic format (`plate_metadata.csv`) 
- Graceful parsing with malformed line skipping

**Image Bundling**: 
- SourcePlateImages folder added as Xcode "folder reference" (blue folder)
- Avoids build conflicts from duplicate filenames across states
- PlateImageService implements two-tier caching (plate-specific + shared common images)

**Persistence**: 
- Games: UserDefaults with JSON encoding
- Preferences: UserDefaults for recent states, default mode
- No Core Data usage despite .xcdatamodeld presence

### UI Architecture

**Tab-Based Navigation**: MainTabView with 4 tabs
- Games: Primary entry point, game management
- Plate Gallery: State-filtered plate exploration with search
- Progress: Collection tracking and maps
- Settings: App preferences and data management

**Component Strategy**:
- AsyncPlateImageView: Async image loading with caching
- Reusable components in Views/Components/
- PlateLogging workflow for guided plate selection

### Critical Implementation Notes

**Asset Bundling**: SourcePlateImages MUST be added as folder reference (blue folder) in Xcode, not individual files, to avoid "Multiple commands produce" build errors from duplicate image names across states.

**CSV Parsing**: Enhanced CSV includes confidence scores from experimental ML classifications. Parser handles quoted fields with commas and skips malformed lines.

**Image Loading**: PlateImageService handles shared images (like MISSING.png) efficiently across multiple states using dual cache strategy.

**Game State**: CollectedPlate equality based on state+plateTitle combination. State Collection mode enforces one plate per state by replacing previous selection.

## Development Workflow

### Git and GitHub Practices

**Branching Strategy**:
- Use feature branches for all development work
- Branch from main: `git checkout -b feature/descriptive-name`
- Keep feature branches focused and short-lived

**Commit Standards**:
- Make frequent, logical commits with clear messages
- Include appropriate documentation in code as you work
- Commit messages should be concise but descriptive
- Always include Claude Code attribution in commits:
  ```
  🤖 Generated with [Claude Code](https://claude.ai/code)
  
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

**GitHub Integration**:
- Reference GitHub issues in commits when applicable: "Fix Browse tab loading - resolves #7"
- Create pull requests for all feature work
- Update relevant GitHub issues with progress and resolution status
- Push branches regularly to maintain backup and collaboration
- **Issue Management**: 
- **ALWAYS document progress**: When completing GitHub issues, you MUST add a concise completion summary comment to the issue using `gh issue comment` before the user closes it
- **Keep documentation concise**: Include key improvements, user experience results, and testing status. Avoid exhaustive technical details or code snippets unless specifically requested
- **Use structured format**: Include summary, main changes, and testing notes. Focus on outcomes rather than implementation details
- **Let user close issues**: Update issue status with progress comments, but let user review and close issues themselves

**Code Documentation**:
- Add concise inline documentation for complex logic
- Document service methods with purpose and parameters
- Explain architectural decisions in comments when non-obvious
- Keep documentation current with code changes

### GitHub Issue Workflow

**Systematic Issue Processing**:
- Work through issues in numerical order (lowest first)
- Use `gh issue list --state open --limit 10` to see current issues
- Use `gh issue view [number]` to get full issue details
- Always check issue status and dependencies before starting

**Issue Completion Process**:
1. Implement the requested changes
2. Test thoroughly across device orientations
3. Commit with descriptive messages referencing issue number
4. Document completion with `gh issue comment [number]` using structured format
5. Let user review and close issues - don't close automatically

### Example Workflow:
```bash
# Check current issues
gh issue list --state open --limit 10
gh issue view 25

# Create feature branch
git checkout -b feature/issue-25-progress-design

# Make changes with regular commits
git add -A
git commit -m "Unify progress view design - resolves #25

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push branch regularly
git push -u origin feature/issue-25-progress-design

# Document completion
gh issue comment 25 --body "✅ Issue completed with [details]"
```

## Current Development Status

**Recently Completed** (as of 2025-06-15):
- ✅ Issue #16: Tab renaming to "Games"
- ✅ Issue #17: State name display in game interface
- ✅ Issue #18: Default state selection in plate logging
- ✅ Issue #21: State picker tap targets (already resolved)
- ✅ Issue #24: Adaptive game name display for long titles
- ✅ Issue #25: Unified progress view design with uniform stat boxes

**Active Branch**: `feature/ios-architecture-setup`

**Open Issues for Future Work**:
- Issue #6: Metadata Enhancement Project (Future milestone)
- Issue #8: Enhanced Game Modes (Future milestone)

**Next Steps**: All immediate development work complete. Ready for user testing and feedback.

## UI Design Patterns

### Consistent Component Design

**Stat Box Pattern** (GameDetailView & ProgressView):
```swift
// Uniform height with color coding
.frame(maxWidth: .infinity, minHeight: 80)
.padding(.vertical, 12)
.background(Color(.systemBackground))
.cornerRadius(8)

// Text wrapping without truncation
.fixedSize(horizontal: false, vertical: true)
.multilineTextAlignment(.center)
```

**Color Coding Standards**:
- Green: Plates Collected, positive metrics
- Orange: States, regional metrics  
- Purple: Scores, achievements
- Blue: Completion percentages, progress

**Responsive Grid Pattern**:
```swift
LazyVGrid(columns: ResponsiveLayout.responsiveColumns(
    geometry: geometry, 
    portraitColumns: 2, 
    landscapeColumns: 4
), spacing: 16)
```

### Navigation Title Handling

**Adaptive Title Display** (GameDetailView):
- Short names (≤25 chars): `.large` navigation titles
- Medium names (26-35 chars): `.inline` navigation titles
- Very long names (>35 chars): Custom header with text wrapping

### Text Handling Principles

**Never Truncate Text**: Always allow proper wrapping with `.fixedSize(horizontal: false, vertical: true)`
**Maintain Uniform Heights**: Use `minHeight` constraints to ensure visual consistency
**Responsive Behavior**: Test all text content across iPhone portrait/landscape orientations

## SwiftUI Patterns Used

**Environment Object Injection**:
```swift
@EnvironmentObject var gameManager: GameManagerService
@EnvironmentObject var plateDataService: PlateDataService
```

**Sheet Presentation**:
```swift
@State private var showingSheet = false
.sheet(isPresented: $showingSheet) { ContentView() }
```

**AsyncImage with Caching** (via AsyncPlateImageView):
- Two-tier caching strategy for performance
- Graceful fallback for missing images
- Consistent corner radius and aspect ratio

**State Management**:
- Use `@State` for view-local state
- Use `@Published` in services for shared state
- Leverage `@EnvironmentObject` for dependency injection

## Testing Strategy

**UI Consistency Verification**:
- Test all changes in both portrait and landscape orientations
- Verify text wrapping behavior with long content
- Check responsive grid behavior on different screen sizes
- Validate color consistency across related views

**Build Verification**:
```bash
# Always run clean build after UI changes
xcodebuild -scheme PlateSpy -destination 'platform=iOS Simulator,name=iPhone 16' clean build
```

**Manual Testing Checklist**:
- Navigate through all affected screens
- Test with varying content lengths (short/long game names, etc.)
- Verify no text truncation occurs
- Check uniform component heights
- Test responsive behavior on rotation