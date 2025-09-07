#!/bin/bash

# Rain Build Script
# Cross-compiles for multiple platforms and creates GitHub releases

set -e

# Configuration
PROJECT_NAME="rain"
BUILD_DIR="dist"
BINARIES_DIR="$BUILD_DIR/binaries"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build targets
declare -a TARGETS=(
    "windows/amd64/.exe/windows-amd64"
    "windows/386/.exe/windows-386"
    "linux/amd64//linux-amd64"
    "linux/386//linux-386"
    "linux/arm64//linux-arm64"
    "darwin/amd64//macos-amd64"
    "darwin/arm64//macos-arm64"
    "android/arm64//android-arm64"
)

# Parse command line arguments
VERSION=""
SKIP_BUILD=false
SKIP_RELEASE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-release)
            SKIP_RELEASE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --version VERSION    Set version (default: auto-increment)"
            echo "  --skip-build            Skip building binaries"
            echo "  --skip-release          Skip creating GitHub release"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

get_next_version() {
    # Get the latest git tag
    local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [[ -z "$latest_tag" ]]; then
        echo "v1.0.0"
        return
    fi
    
    # Remove 'v' prefix and split version
    local version=${latest_tag#v}
    IFS='.' read -ra PARTS <<< "$version"
    
    # Increment patch version
    local major=${PARTS[0]}
    local minor=${PARTS[1]}
    local patch=$((PARTS[2] + 1))
    
    echo "v${major}.${minor}.${patch}"
}

build_binaries() {
    print_color $GREEN "Building binaries for all platforms..."
    
    # Clean and create build directory
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$BINARIES_DIR"
    
    for target in "${TARGETS[@]}"; do
        IFS='/' read -ra PARTS <<< "$target"
        local goos="${PARTS[0]}"
        local goarch="${PARTS[1]}"
        local ext="${PARTS[2]}"
        local name="${PARTS[3]}"
        
        print_color $YELLOW "Building for $name..."
        
        export GOOS="$goos"
        export GOARCH="$goarch"
        export CGO_ENABLED="0"
        
        local output_name="${PROJECT_NAME}${ext}"
        local output_path="$BINARIES_DIR/$name/$output_name"
        
        # Create platform directory
        mkdir -p "$BINARIES_DIR/$name"
        
        # Build binary
        if go build -ldflags='-s -w' -o "$output_path" .; then
            print_color $GREEN "✓ Built $name"
        else
            print_color $RED "✗ Failed to build $name"
            exit 1
        fi
    done
    
    # Reset environment variables
    unset GOOS
    unset GOARCH
    unset CGO_ENABLED
}

create_archives() {
    print_color $GREEN "Creating archives..."
    
    for target in "${TARGETS[@]}"; do
        IFS='/' read -ra PARTS <<< "$target"
        local name="${PARTS[3]}"
        local platform_dir="$BINARIES_DIR/$name"
        
        if [[ -d "$platform_dir" ]]; then
            local archive_name="${PROJECT_NAME}-${VERSION}-${name}"
            
            # Create archive based on platform
            if [[ "$name" == windows-* ]]; then
                (cd "$platform_dir" && zip -r "../../${archive_name}.zip" .)
                print_color $GREEN "✓ Created ${archive_name}.zip"
            else
                (cd "$platform_dir" && tar -czf "../../${archive_name}.tar.gz" .)
                print_color $GREEN "✓ Created ${archive_name}.tar.gz"
            fi
        fi
    done
}

generate_release_notes() {
    print_color $GREEN "Generating release notes..."
    
    local notes="## Rain $VERSION

### What's New
- Cross-platform builds for Windows, Linux, macOS, and Android
- Optimized binaries with reduced size
- Improved build automation

### Downloads
"
    
    for target in "${TARGETS[@]}"; do
        IFS='/' read -ra PARTS <<< "$target"
        local name="${PARTS[3]}"
        local platform_dir="$BINARIES_DIR/$name"
        
        if [[ -d "$platform_dir" ]]; then
            local archive_name="${PROJECT_NAME}-${VERSION}-${name}"
            
            if [[ "$name" == windows-* ]]; then
                notes+="\n- **$name**: [${archive_name}.zip](${archive_name}.zip)"
            else
                notes+="\n- **$name**: [${archive_name}.tar.gz](${archive_name}.tar.gz)"
            fi
        fi
    done
    
    notes+="

### Installation
1. Download the appropriate archive for your platform
2. Extract the binary
3. Run: \`./rain\` (Unix) or \`rain.exe\` (Windows)

### Requirements
- Go 1.11 or later (for building from source)"
    
    echo -e "$notes"
}

create_github_release() {
    local tag=$1
    local notes=$2
    
    print_color $GREEN "Creating GitHub release..."
    
    # Create and push tag
    git tag "$tag"
    git push origin "$tag"
    
    # Create temporary notes file
    local temp_notes_file="temp-release-notes.md"
    echo -e "$notes" > "$temp_notes_file"
    
    # Build GitHub CLI command
    local gh_cmd="gh release create '$tag' --title 'Rain $tag' --notes-file '$temp_notes_file'"
    
    # Add all archive files
    for file in "$BUILD_DIR"/*.zip "$BUILD_DIR"/*.tar.gz; do
        if [[ -f "$file" ]]; then
            gh_cmd+=" '$file'"
        fi
    done
    
    print_color $CYAN "Running: $gh_cmd"
    
    if eval "$gh_cmd"; then
        print_color $GREEN "✓ GitHub release created successfully!"
    else
        print_color $RED "GitHub CLI failed. Please install GitHub CLI (gh) or create release manually."
        print_color $YELLOW "Release notes saved to release-notes.md"
        echo -e "$notes" > "release-notes.md"
        exit 1
    fi
    
    # Clean up temp file
    rm -f "$temp_notes_file"
}

# Main execution
main() {
    print_color $CYAN "Rain Build Script"
    print_color $CYAN "================"
    
    # Determine version
    if [[ -z "$VERSION" ]]; then
        VERSION=$(get_next_version)
    fi
    print_color $WHITE "Version: $VERSION"
    
    # Build binaries
    if [[ "$SKIP_BUILD" != true ]]; then
        build_binaries
        create_archives
    fi
    
    # Create GitHub release
    if [[ "$SKIP_RELEASE" != true ]]; then
        local release_notes=$(generate_release_notes)
        create_github_release "$VERSION" "$release_notes"
    fi
    
    print_color $GREEN "\nBuild completed successfully!"
    print_color $WHITE "Binaries available in: $BUILD_DIR"
}

# Run main function
main "$@"
