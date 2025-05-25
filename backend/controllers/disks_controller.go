package controllers

import (
	"net/http"
	"reflect"
)

type DisksController struct {
}

// BeforeAction implements Controller.
func (d DisksController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}
}

// Name implements Controller.
func (d DisksController) Name() string {
	return reflect.TypeOf(d).Name()
}

// get disk usage

// list disks

// mount a disk

// unmount a disk

var _ Controller = DisksController{}
