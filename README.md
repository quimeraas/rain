# Rain 🌧️

A simple Go program that creates an animated rain effect with clouds in the terminal.

## Features

- Animated rain falling from clouds
- Colorful terminal output with blue rain and white clouds
- Continuous animation loop
- Various rain characters for visual variety

## Requirements

- Go 1.11 or later

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Cod-e-Codes/rain.git
cd rain
```

2. Run the program:
```bash
go run main.go
```

## Usage

Simply run the program and watch the animated rain effect! The program will continuously display clouds with falling rain. Press `Ctrl+C` to stop the animation.

## How it works

The program generates animated clouds with rain using:
- White clouds made of ASCII characters
- Blue rain characters that fall from the clouds
- Random rain density (60% chance per position)
- Screen clearing for smooth animation
- 200ms delay between frames

## License

This project is open source and available under the [MIT License](LICENSE).
