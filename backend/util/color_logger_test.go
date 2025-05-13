package util

import (
	"bytes"
	"log"
	"os"
	"testing"
)

// Helper function to capture log output
func captureLogOutput(f func()) string {
	var buf bytes.Buffer
	log.SetOutput(&buf)
	// Preserve original flags and prefix
	originalFlags := log.Flags()
	originalPrefix := log.Prefix()
	log.SetFlags(0) // Disable timestamps for predictable output
	log.SetPrefix("")

	f()

	// Restore original logger settings
	log.SetOutput(os.Stderr)
	log.SetFlags(originalFlags)
	log.SetPrefix(originalPrefix)
	return buf.String()
}

func TestLogColor(t *testing.T) {
	testCases := []struct {
		name   string
		color  string
		format string
		args   []any
		want   string
	}{
		{"Known Color", "red", "Hello %s", []any{"World"}, "\033[38;2;255;0;0mHello World\033[0m\n"},
		{"Unknown Color", "pink", "Number %d", []any{123}, "\033[38;2;pinkmNumber 123\033[0m\n"}, // Uses color name directly if not in map
		{"No Args", "blue", "Just text", []any{}, "\033[38;2;0;0;255mJust text\033[0m\n"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			output := captureLogOutput(func() {
				LogColor(tc.color, tc.format, tc.args...)
			})
			if output != tc.want {
				t.Errorf("LogColor(%q, %q, %v) logged %q; want %q", tc.color, tc.format, tc.args, output, tc.want)
			}
		})
	}
}
