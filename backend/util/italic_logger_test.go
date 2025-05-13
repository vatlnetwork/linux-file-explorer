package util

import (
	"testing"
)

// Using the same captureLogOutput helper potentially defined in color_logger_test.go
// If run separately, this helper would need to be defined here too.

func TestLogItalic(t *testing.T) {
	testCases := []struct {
		name   string
		format string
		args   []any
		want   string
	}{
		{"Simple String", "Hello %s", []any{"Italic"}, "\033[3mHello Italic\033[0m\n"},
		{"Number", "Value: %d", []any{42}, "\033[3mValue: 42\033[0m\n"},
		{"No Args", "Just italic text", []any{}, "\033[3mJust italic text\033[0m\n"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			output := captureLogOutput(func() {
				LogItalic(tc.format, tc.args...)
			})
			if output != tc.want {
				t.Errorf("LogItalic(%q, %v) logged %q; want %q", tc.format, tc.args, output, tc.want)
			}
		})
	}
}

func TestLogItalicColor(t *testing.T) {
	testCases := []struct {
		name   string
		color  string
		format string
		args   []any
		want   string
	}{
		{"Known Color", "green", "Success: %s", []any{"OK"}, "\033[3m\033[38;2;0;150;50mSuccess: OK\033[0m\n"},
		{"Unknown Color", "orange", "Warning: %d", []any{99}, "\033[3m\033[38;2;orangemWarning: 99\033[0m\n"},
		{"No Args", "blue", "Info message", []any{}, "\033[3m\033[38;2;0;0;255mInfo message\033[0m\n"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			output := captureLogOutput(func() {
				LogItalicColor(tc.color, tc.format, tc.args...)
			})
			if output != tc.want {
				t.Errorf("LogItalicColor(%q, %q, %v) logged %q; want %q", tc.color, tc.format, tc.args, output, tc.want)
			}
		})
	}
}
