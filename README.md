# Rain

[![Go Report Card](https://goreportcard.com/badge/github.com/Cod-e-Codes/rain)](https://goreportcard.com/report/github.com/Cod-e-Codes/rain)
[![CI](https://github.com/Cod-e-Codes/rain/actions/workflows/ci.yml/badge.svg)](https://github.com/Cod-e-Codes/rain/actions/workflows/ci.yml)

A Go program that displays animated rain falling from clouds in the terminal.

<img src="rain-demo.gif" width="400" alt="Rain Demo">

## Requirements

Go 1.11 or later

## Installation

### Pre-built Binaries (Recommended)
Download the latest release from [GitHub Releases](https://github.com/Cod-e-Codes/rain/releases/latest) and extract the appropriate binary for your platform.

### From Source
```bash
git clone https://github.com/Cod-e-Codes/rain.git
cd rain
go run main.go
```

## Usage

Run the program to display animated rain. Press Ctrl+C to exit.

## Implementation

- Displays white ASCII clouds with blue rain characters
- 60% probability of rain at each position
- 200ms frame delay
- Clears screen between frames

## Releases

- **v1.0.0** - Initial release with cross-platform builds for Windows, Linux, macOS, and Android

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
