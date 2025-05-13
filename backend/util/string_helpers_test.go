package util

import (
	"testing"
)

func TestIsString(t *testing.T) {
	testCases := []struct {
		name     string
		input    any
		expected bool
	}{
		{"string", "hello", true},
		{"empty string", "", true},
		{"int", 123, false},
		{"bool", true, false},
		{"nil", nil, false},
		{"struct", struct{}{}, false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := IsString(tc.input)
			if result != tc.expected {
				t.Errorf("IsString(%v) = %v; want %v", tc.input, result, tc.expected)
			}
		})
	}
}

func TestIsStringEmpty(t *testing.T) {
	testCases := []struct {
		name     string
		input    any
		expected bool
	}{
		{"empty string", "", true},
		{"whitespace string", "   ", true},
		{"non-empty string", "hello", false},
		{"int", 123, true},           // Non-strings are considered empty
		{"bool", false, true},        // Non-strings are considered empty
		{"nil", nil, true},           // Non-strings are considered empty
		{"struct", struct{}{}, true}, // Non-strings are considered empty
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := IsStringEmpty(tc.input)
			if result != tc.expected {
				t.Errorf("IsStringEmpty(%v) = %v; want %v", tc.input, result, tc.expected)
			}
		})
	}
}
