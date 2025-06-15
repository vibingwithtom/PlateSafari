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
- **ALWAYS document progress**: When completing GitHub issues, you MUST add a detailed completion summary comment to the issue using `gh issue comment` before the user closes it
- **Required documentation includes**: Key improvements, technical implementation details, code changes, bug fixes, user experience results, testing notes, and any backward compatibility considerations
- **Use structured format**: Include summary, changes made, technical details, and testing notes sections for clarity
- **Let user close issues**: Update issue status with progress comments, but let user review and close issues themselves

**Code Documentation**:
- Add concise inline documentation for complex logic
- Document service methods with purpose and parameters
- Explain architectural decisions in comments when non-obvious
- Keep documentation current with code changes

### Example Workflow:
```bash
# Create feature branch
git checkout -b feature/new-game-mode

# Make changes with regular commits
git add -A
git commit -m "Add new game mode structure

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push branch regularly
git push -u origin feature/new-game-mode

# Create PR when ready
gh pr create --title "Add new game mode" --body "Resolves #12"
```