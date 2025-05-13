package controllers

import "net/http"

type Controller interface {
	Name() string
	BeforeAction(handler http.HandlerFunc) http.HandlerFunc
}
