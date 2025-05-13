package controllers

import (
	"net/http"
	"reflect"
)

type FileSystemController struct {
}

// BeforeAction implements Controller.
func (f FileSystemController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}
}

// Name implements Controller.
func (f FileSystemController) Name() string {
	return reflect.TypeOf(f).Name()
}

// Read files and folders from a directory

// Read a file

// Rename files and folders

// Delete files and folders

// Create folders

// Upload files

// Move files and folders

// Copy files and folders

// Get top n number of files by size in a directory

// Assign a tag to a file or folder

// Remove a tag from a file or folder

// Get all files with a given tag

var _ Controller = FileSystemController{}
