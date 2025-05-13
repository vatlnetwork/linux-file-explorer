package controllers

import (
	"net/http"
	"reflect"
)

type AppsController struct {
}

// BeforeAction implements Controller.
func (a AppsController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}
}

// Name implements Controller.
func (a AppsController) Name() string {
	return reflect.TypeOf(a).Name()
}

// Get all apps

var _ Controller = AppsController{}
