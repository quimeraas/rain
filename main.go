package main

import (
	"fmt"
	"math/rand"
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

// generate a single cloud with its own rain
func generateCloudWithRain() []string {
	lines := make([]string, 6)

	// cloud lines
	for i, c := range cloud {
		lines[i] = white + c + reset
	}

	width := len(cloud[0])

	// rain lines
	for i := 2; i < 6; i++ {
		line := ""
		for j := 0; j < width; j++ {
			if rand.Float64() < 0.6 {
				line += blue + string(rainChars[rand.Intn(len(rainChars))]) + reset
			} else {
				line += " "
			}
		}
		lines[i] = line
	}

	return lines
}

func main() {
	for {
		fmt.Print("\033[H\033[2J") // clear screen

		// generate just one cloud
		c := generateCloudWithRain()
		for _, line := range c {
			fmt.Println(line)
		}

		time.Sleep(200 * time.Millisecond)
	}
}
