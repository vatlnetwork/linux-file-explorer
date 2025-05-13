package controllers

import (
	"net/http"
	"reflect"
)

type TagsController struct {
}

// BeforeAction implements Controller.
func (t TagsController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}
}

// Name implements Controller.
func (t TagsController) Name() string {
	return reflect.TypeOf(t).Name()
}

// Create a tag

// Update a tag

// Delete a tag

// Get all tags

// Get a tag by id

var _ Controller = TagsController{}
