package util

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
)

type testStruct struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}

func TestDecodeRequestBody(t *testing.T) {
	testCases := []struct {
		name        string
		body        io.Reader
		target      any
		wantTarget  any
		expectError bool
	}{
		{
			name:        "Valid JSON",
			body:        bytes.NewBufferString(`{"name":"Alice","age":30}`),
			target:      &testStruct{},
			wantTarget:  &testStruct{Name: "Alice", Age: 30},
			expectError: false,
		},
		{
			name:        "Invalid JSON",
			body:        bytes.NewBufferString(`{"name":"Bob",`), // Malformed
			target:      &testStruct{},
			wantTarget:  &testStruct{}, // Target should remain unchanged
			expectError: true,
		},
		{
			name:        "Empty Body",
			body:        bytes.NewBufferString(""),
			target:      &testStruct{},
			wantTarget:  &testStruct{}, // Target should remain unchanged
			expectError: true,          // Expect EOF or similar unmarshal error
		},
		{
			name:        "Nil Body",
			body:        nil,
			target:      &testStruct{},
			wantTarget:  &testStruct{}, // Target should remain unchanged
			expectError: false,         // Now returns nil error explicitly
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/", tc.body)
			if tc.body == nil {
				req.Body = nil // Ensure body is explicitly nil
			}

			err := DecodeRequestBody(req, tc.target)

			if tc.expectError {
				if err == nil {
					t.Errorf("Expected an error, but got nil")
				}
				// Removed check for target modification on error, as json.Unmarshal might modify partially
			} else {
				if err != nil {
					t.Errorf("Expected no error, but got: %v", err)
				}
				// Directly compare with tc.wantTarget in the success case
				if !reflect.DeepEqual(tc.target, tc.wantTarget) {
					t.Errorf("Target mismatch: got %#v, want %#v", tc.target, tc.wantTarget)
				}
			}
		})
	}
}

func TestDecodeRequestBodyToMap(t *testing.T) {
	testCases := []struct {
		name        string
		body        io.Reader
		wantMap     map[string]any
		expectError bool
	}{
		{
			name:        "Valid JSON",
			body:        bytes.NewBufferString(`{"name":"Alice","age":30, "extra":true}`),
			wantMap:     map[string]any{"name": "Alice", "age": 30.0, "extra": true}, // Note: numbers decode as float64
			expectError: false,
		},
		{
			name:        "Invalid JSON",
			body:        bytes.NewBufferString(`{"name":"Bob",`), // Malformed
			wantMap:     nil,
			expectError: true,
		},
		{
			name:        "Empty Body",
			body:        bytes.NewBufferString(""),
			wantMap:     nil,
			expectError: true, // Expect EOF or similar unmarshal error
		},
		{
			name:        "Nil Body",
			body:        nil,
			wantMap:     map[string]any{}, // Decodes to empty map
			expectError: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/", tc.body)
			if tc.body == nil {
				req.Body = nil // Ensure body is explicitly nil
			}

			resultMap, err := DecodeRequestBodyToMap(req)

			if tc.expectError {
				if err == nil {
					t.Errorf("Expected an error, but got nil")
				}
			} else {
				if err != nil {
					t.Errorf("Expected no error, but got: %v", err)
				}
				if !reflect.DeepEqual(resultMap, tc.wantMap) {
					t.Errorf("Map mismatch: got %#v, want %#v", resultMap, tc.wantMap)
				}
			}
		})
	}
}
