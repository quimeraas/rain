package main

import (
	"fmt"
	"math/rand"
	"os"
	"strings"
	"time"
)

const (
	white = "\033[97m"
	blue  = "\033[34m"
	reset = "\033[0m"
)

var cloud = []string{
	"  (   ).  ",
	" (___(__) ",
}
var rainChars = []rune{'‘', '’', '|', '.', '˙'}
var precomputedCloud []string // Precomputed cloud strings with color

// Precompute cloud strings with ANSI codes
func init() {
	precomputedCloud = make([]string, len(cloud))
	for i, c := range cloud {
		precomputedCloud[i] = white + c + reset
	}
}

// generateCloudWithRain generates a single string for the entire frame
func generateCloudWithRain() string {
	var frame strings.Builder
	frame.Grow(6 * (len(cloud[0]) + 20)) // Preallocate: ~6 lines, ~10 chars + ANSI codes + newlines

	// Add precomputed cloud lines
	for _, c := range precomputedCloud {
		frame.WriteString(c)
		frame.WriteByte('\n')
	}

	// Generate rain lines
	width := len(cloud[0])
	for i := 2; i < 6; i++ {
		var line strings.Builder
		line.Grow(width * 7) // Preallocate: ~10 chars + ANSI codes
		for j := 0; j < width; j++ {
			if rand.Float64() < 0.6 {
				line.WriteByte(' ')
			} else {
				line.WriteString(blue)
				line.WriteRune(rainChars[rand.Intn(len(rainChars))])
				line.WriteString(reset)
			}
		}
		frame.WriteString(line.String())
		frame.WriteByte('\n')
	}

	return frame.String()
}

func main() {
	// Ensure stdout is unbuffered for smoother animation
	stdout := os.Stdout
	for {
		fmt.Fprint(stdout, "\033[H\033[2J") // Clear screen
		fmt.Fprint(stdout, generateCloudWithRain())
		time.Sleep(200 * time.Millisecond)
	}
}
