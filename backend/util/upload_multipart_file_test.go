package util

import (
	"bytes"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"testing"
)

func TestUploadMultipartFile(t *testing.T) {
	// Create a temporary directory for tests
	tempDir, err := os.MkdirTemp("", "upload-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	testCases := []struct {
		name        string
		fileContent string
		fileName    string
		contentType string
		expectError bool
	}{
		{
			name:        "Upload text file",
			fileContent: "Hello, World!",
			fileName:    "test.txt",
			contentType: "text/plain",
			expectError: false,
		},
		{
			name:        "Upload JSON file",
			fileContent: `{"key": "value"}`,
			fileName:    "data.json",
			contentType: "application/json",
			expectError: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create a multipart file
			var buffer bytes.Buffer
			writer := multipart.NewWriter(&buffer)
			part, err := writer.CreateFormFile("file", tc.fileName)
			if err != nil {
				t.Fatalf("Failed to create form file: %v", err)
			}
			_, err = io.Copy(part, bytes.NewBufferString(tc.fileContent))
			if err != nil {
				t.Fatalf("Failed to copy content to form file: %v", err)
			}
			writer.Close()

			// Create a multipart file header
			reader := multipart.NewReader(bytes.NewReader(buffer.Bytes()), writer.Boundary())
			form, err := reader.ReadForm(32 << 20) // 32MB max memory
			if err != nil {
				t.Fatalf("Failed to read form: %v", err)
			}

			fileHeader := form.File["file"][0]
			fileHeader.Header.Set("Content-Type", tc.contentType)

			// Call the function
			response, err := UploadMultipartFile(fileHeader, tempDir)

			// Verify error expectation
			if tc.expectError && err == nil {
				t.Error("Expected error but got nil")
			}
			if !tc.expectError && err != nil {
				t.Errorf("Expected no error but got: %v", err)
			}

			if !tc.expectError {
				// Verify the response
				if response.FileName != tc.fileName {
					t.Errorf("Expected filename %s, got %s", tc.fileName, response.FileName)
				}
				if response.FileType != tc.contentType {
					t.Errorf("Expected content type %s, got %s", tc.contentType, response.FileType)
				}
				if response.Extension != filepath.Ext(tc.fileName) {
					t.Errorf("Expected extension %s, got %s", filepath.Ext(tc.fileName), response.Extension)
				}
				if response.Path == "" {
					t.Error("Expected non-empty path")
				}

				// Verify file was actually uploaded
				uploadedFilePath := filepath.Join(tempDir, response.Path)
				if _, err := os.Stat(uploadedFilePath); os.IsNotExist(err) {
					t.Errorf("Uploaded file does not exist at %s", uploadedFilePath)
				}

				// Check file content
				content, err := os.ReadFile(uploadedFilePath)
				if err != nil {
					t.Fatalf("Failed to read uploaded file: %v", err)
				}
				if string(content) != tc.fileContent {
					t.Errorf("Expected file content %s, got %s", tc.fileContent, string(content))
				}
			}
		})
	}
}
