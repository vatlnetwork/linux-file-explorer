package routes

import (
	"golang-web-core/controllers"
	"golang-web-core/srv/cfg"
	"golang-web-core/srv/route"
	"net/http"
)

type Router struct {
	config cfg.Config
}

func NewRouter(c cfg.Config) Router {
	return Router{
		config: c,
	}
}

func (r Router) Routes(appController controllers.ApplicationController) []route.Route {
	// this is where you define your routes. you can do this however you like so long as you populate
	// all of the fields in each route. each field is necessary. if you have a lot of routes, you can split
	// your routes up into multiple files, so long as they are all returned here

	routes := []route.Route{
		{
			Pattern:        "/favicon.ico",
			Method:         http.MethodGet,
			Handler:        appController.Favicon,
			ControllerName: appController.Name(),
		},
	}

	appsController := appController.GetController("AppsController").(controllers.AppsController)
	routes = append(routes, appsController.Routes()...)

	return routes
}
