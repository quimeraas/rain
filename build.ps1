# Rain Build Script
# Cross-compiles for multiple platforms and creates GitHub releases

param(
    [string]$Version = "",
    [switch]$SkipBuild = $false,
    [switch]$SkipRelease = $false
)

# Configuration
$PROJECT_NAME = "rain"
$BUILD_DIR = "dist"
$BINARIES_DIR = "$BUILD_DIR/binaries"

# Build targets
$TARGETS = @(
    @{ GOOS = "windows"; GOARCH = "amd64"; EXT = ".exe"; NAME = "windows-amd64" },
    @{ GOOS = "windows"; GOARCH = "386"; EXT = ".exe"; NAME = "windows-386" },
    @{ GOOS = "linux"; GOARCH = "amd64"; EXT = ""; NAME = "linux-amd64" },
    @{ GOOS = "linux"; GOARCH = "386"; EXT = ""; NAME = "linux-386" },
    @{ GOOS = "linux"; GOARCH = "arm64"; EXT = ""; NAME = "linux-arm64" },
    @{ GOOS = "darwin"; GOARCH = "amd64"; EXT = ""; NAME = "macos-amd64" },
    @{ GOOS = "darwin"; GOARCH = "arm64"; EXT = ""; NAME = "macos-arm64" },
    @{ GOOS = "android"; GOARCH = "arm64"; EXT = ""; NAME = "android-arm64" }
)

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Get-NextVersion {
    # Get the latest git tag
    $latestTag = git describe --tags --abbrev=0 2>$null
    if (-not $latestTag) {
        return "v1.0.0"
    }
    
    # Remove 'v' prefix and split version
    $version = $latestTag -replace '^v', ''
    $parts = $version -split '\.'
    
    # Increment patch version
    $parts[2] = [int]$parts[2] + 1
    return "v$($parts -join '.')"
}

function Build-Binaries {
    Write-ColorOutput "Building binaries for all platforms..." "Green"
    
    # Clean and create build directory
    if (Test-Path $BUILD_DIR) {
        Remove-Item $BUILD_DIR -Recurse -Force
    }
    New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null
    New-Item -ItemType Directory -Path $BINARIES_DIR -Force | Out-Null
    
    foreach ($target in $TARGETS) {
        Write-ColorOutput "Building for $($target.NAME)..." "Yellow"
        
        $env:GOOS = $target.GOOS
        $env:GOARCH = $target.GOARCH
        $env:CGO_ENABLED = "0"
        
        $outputName = "$PROJECT_NAME$($target.EXT)"
        $outputPath = "$BINARIES_DIR/$($target.NAME)/$outputName"
        
        # Create platform directory
        New-Item -ItemType Directory -Path "$BINARIES_DIR/$($target.NAME)" -Force | Out-Null
        
        # Build binary
        $buildCmd = "go build -ldflags='-s -w' -o '$outputPath' ."
        Invoke-Expression $buildCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ Built $($target.NAME)" "Green"
        } else {
            Write-ColorOutput "✗ Failed to build $($target.NAME)" "Red"
        }
    }
    
    # Reset environment variables
    Remove-Item Env:GOOS -ErrorAction SilentlyContinue
    Remove-Item Env:GOARCH -ErrorAction SilentlyContinue
    Remove-Item Env:CGO_ENABLED -ErrorAction SilentlyContinue
}

function New-Archives {
    Write-ColorOutput "Creating archives..." "Green"
    
    foreach ($target in $TARGETS) {
        $platformDir = "$BINARIES_DIR/$($target.NAME)"
        if (Test-Path $platformDir) {
            $archiveName = "$PROJECT_NAME-$VERSION-$($target.NAME)"
            
            # Create archive based on platform
            if ($target.NAME -like "windows-*") {
                Compress-Archive -Path "$platformDir/*" -DestinationPath "$BUILD_DIR/$archiveName.zip" -Force
                Write-ColorOutput "✓ Created $archiveName.zip" "Green"
            } else {
                # Use tar for Unix-like systems
                $tarCmd = "tar -czf '$BUILD_DIR/$archiveName.tar.gz' -C '$platformDir' ."
                Invoke-Expression $tarCmd
                Write-ColorOutput "✓ Created $archiveName.tar.gz" "Green"
            }
        }
    }
}

function New-ReleaseNotes {
    Write-ColorOutput "Generating release notes..." "Green"
    
    $notes = @"
## Rain $VERSION

### What's New
- Cross-platform builds for Windows, Linux, macOS, and Android
- Optimized binaries with reduced size
- Improved build automation

### Downloads
"@
    
    foreach ($target in $TARGETS) {
        $platformDir = "$BINARIES_DIR/$($target.NAME)"
        if (Test-Path $platformDir) {
            $archiveName = "$PROJECT_NAME-$VERSION-$($target.NAME)"
            
            if ($target.NAME -like "windows-*") {
                $notes += "`n- **$($target.NAME)**: [$archiveName.zip]($archiveName.zip)"
            } else {
                $notes += "`n- **$($target.NAME)**: [$archiveName.tar.gz]($archiveName.tar.gz)"
            }
        }
    }
    
    $notes += @"

### Installation
1. Download the appropriate archive for your platform
2. Extract the binary
3. Run: `./rain` (Unix) or `rain.exe` (Windows)

### Requirements
- Go 1.11 or later (for building from source)
"@
    
    return $notes
}

function New-GitHubRelease {
    param([string]$Tag, [string]$Notes)
    
    Write-ColorOutput "Creating GitHub release..." "Green"
    
    # Create and push tag
    git tag $Tag
    git push origin $Tag
    
    # Try GitHub CLI first
    $ghCmd = "gh release create '$Tag' --title 'Rain $Tag' --notes '$Notes'"
    $uploadFiles = Get-ChildItem "$BUILD_DIR/*.zip", "$BUILD_DIR/*.tar.gz" | ForEach-Object { "--attach '$($_.FullName)'" }
    $ghCmd += " $($uploadFiles -join ' ')"
    
    Write-ColorOutput "Running: $ghCmd" "Cyan"
    Invoke-Expression $ghCmd
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "GitHub CLI failed. Please install GitHub CLI (gh) or create release manually." "Red"
        Write-ColorOutput "Release notes saved to release-notes.md" "Yellow"
        $Notes | Out-File -FilePath "release-notes.md" -Encoding UTF8
    } else {
        Write-ColorOutput "✓ GitHub release created successfully!" "Green"
    }
}

# Main execution
try {
    Write-ColorOutput "Rain Build Script" "Cyan"
    Write-ColorOutput "================" "Cyan"
    
    # Determine version
    if (-not $Version) {
        $Version = Get-NextVersion
    }
    Write-ColorOutput "Version: $Version" "White"
    
    # Build binaries
    if (-not $SkipBuild) {
        Build-Binaries
        New-Archives
    }
    
    # Create GitHub release
    if (-not $SkipRelease) {
        $releaseNotes = New-ReleaseNotes
        New-GitHubRelease -Tag $Version -Notes $releaseNotes
    }
    
    Write-ColorOutput "`nBuild completed successfully!" "Green"
    Write-ColorOutput "Binaries available in: $BUILD_DIR" "White"
    
} catch {
    Write-ColorOutput "Build failed: $($_.Exception.Message)" "Red"
    exit 1
}
