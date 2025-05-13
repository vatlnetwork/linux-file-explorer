package util

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
)

func TestSendGetRequest(t *testing.T) {
	testCases := []struct {
		name           string
		serverResponse string
		serverStatus   int
		params         url.Values
		expectError    bool
		expectedStatus int
	}{
		{
			name:           "Successful request",
			serverResponse: `{"success": true}`,
			serverStatus:   http.StatusOK,
			params:         url.Values{"key": []string{"value"}},
			expectError:    false,
			expectedStatus: http.StatusOK,
		},
		{
			name:           "Server error",
			serverResponse: `{"error": "Internal error"}`,
			serverStatus:   http.StatusInternalServerError,
			params:         url.Values{},
			expectError:    true,
			expectedStatus: http.StatusInternalServerError,
		},
		{
			name:           "Not found error",
			serverResponse: `{"error": "Resource not found"}`,
			serverStatus:   http.StatusNotFound,
			params:         url.Values{"id": []string{"123"}},
			expectError:    true,
			expectedStatus: http.StatusNotFound,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create a test server
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				// Verify request parameters
				if r.URL.Query().Encode() != tc.params.Encode() {
					t.Errorf("Expected query params %v, got %v", tc.params.Encode(), r.URL.Query().Encode())
				}

				// Verify content type header
				if r.Header.Get("Content-Type") != "application/json" {
					t.Errorf("Expected Content-Type header to be application/json")
				}

				// Return the mock response
				w.WriteHeader(tc.serverStatus)
				w.Write([]byte(tc.serverResponse))
			}))
			defer server.Close()

			// Call the function with our test server URL
			response, status, err := SendGetRequest(server.URL, tc.params)

			// Verify status code
			if status != tc.expectedStatus {
				t.Errorf("Expected status %d, got %d", tc.expectedStatus, status)
			}

			// Verify error expectation
			if tc.expectError && err == nil {
				t.Error("Expected error but got nil")
			}
			if !tc.expectError && err != nil {
				t.Errorf("Expected no error but got: %v", err)
			}

			// For successful requests, verify response body
			if !tc.expectError {
				if string(response) != tc.serverResponse {
					t.Errorf("Expected response %s, got %s", tc.serverResponse, string(response))
				}
			}
		})
	}
}
