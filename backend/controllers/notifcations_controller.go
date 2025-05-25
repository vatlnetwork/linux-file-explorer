package controllers

import (
	"net/http"
	"reflect"
)

type NotificationsController struct {
}

// BeforeAction implements Controller.
func (n NotificationsController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}
}

// Name implements Controller.
func (n NotificationsController) Name() string {
	return reflect.TypeOf(n).Name()
}

// Send notification

var _ Controller = NotificationsController{}
