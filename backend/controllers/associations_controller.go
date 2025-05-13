package controllers

import (
	"net/http"
	"reflect"
)

type AssociationsController struct {
}

// BeforeAction implements Controller.
func (a AssociationsController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}
}

// Name implements Controller.
func (a AssociationsController) Name() string {
	return reflect.TypeOf(a).Name()
}

// Get all associations

// Create an association

// Delete an association

var _ Controller = AssociationsController{}
