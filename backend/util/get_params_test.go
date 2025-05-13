package util

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
)

func TestGetParams(t *testing.T) {
	testCases := []struct {
		name        string
		method      string
		url         string
		body        *bytes.Buffer // Use bytes.Buffer for potential body
		wantParams  map[string]any
		expectError bool
	}{
		{
			name:        "GET with Query Params",
			method:      http.MethodGet,
			url:         "/?name=Alice&age=30&active=true",
			body:        nil,
			wantParams:  map[string]any{"name": "Alice", "age": "30", "active": "true"}, // Query params are strings
			expectError: false,
		},
		{
			name:        "GET with No Params",
			method:      http.MethodGet,
			url:         "/",
			body:        nil,
			wantParams:  map[string]any{},
			expectError: false,
		},
		{
			name:        "POST with Valid JSON Body",
			method:      http.MethodPost,
			url:         "/",
			body:        bytes.NewBufferString(`{"id":123,"status":"pending"}`),
			wantParams:  map[string]any{"id": 123.0, "status": "pending"}, // JSON numbers decode as float64
			expectError: false,
		},
		{
			name:   "POST with Invalid JSON Body",
			method: http.MethodPost,
			url:    "/",
			body:   bytes.NewBufferString(`{"id":123,`), // Invalid JSON
			// In this specific implementation, it falls back to DecodeFormDataToMap,
			// which expects a multipart form. Since the body is invalid JSON *and* not
			// a valid multipart form, DecodeFormDataToMap will also likely error out.
			// The exact error might depend on http internals, but we expect *an* error.
			wantParams:  nil,
			expectError: true,
		},
		{
			name:   "POST with Empty Body",
			method: http.MethodPost,
			url:    "/",
			body:   bytes.NewBufferString(""),
			// DecodeRequestBodyToMap fails (EOF), DecodeFormDataToMap also fails (no boundary etc.)
			wantParams:  nil,
			expectError: true,
		},
		{
			name:        "PUT with Valid JSON Body", // Test another method
			method:      http.MethodPut,
			url:         "/items/1",
			body:        bytes.NewBufferString(`{"value": "test"}`),
			wantParams:  map[string]any{"value": "test"},
			expectError: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			var req *http.Request
			if tc.body != nil {
				req = httptest.NewRequest(tc.method, tc.url, tc.body)
				// Set content type if body is JSON (important for potential future middleware)
				if tc.method != http.MethodGet {
					req.Header.Set("Content-Type", "application/json")
				}
			} else {
				req = httptest.NewRequest(tc.method, tc.url, nil)
			}

			params, err := GetParams(req)

			if tc.expectError {
				if err == nil {
					t.Errorf("Expected an error, but got nil")
				}
			} else {
				if err != nil {
					t.Errorf("Expected no error, but got: %v", err)
				}
				if !reflect.DeepEqual(params, tc.wantParams) {
					t.Errorf("Params mismatch: got %#v, want %#v", params, tc.wantParams)
				}
			}
		})
	}
}
