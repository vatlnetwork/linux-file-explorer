package controllers

import (
	"encoding/json"
	"golang-web-core/domain"
	"golang-web-core/srv/route"
	"golang-web-core/srv/srverr"
	"net/http"
	"reflect"
)

type AppsController struct {
	appRepo domain.AppRepository
}

func NewAppsController(appRepo domain.AppRepository) AppsController {
	return AppsController{appRepo: appRepo}
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

func (a AppsController) Routes() []route.Route {
	return []route.Route{
		{
			Pattern:        "/api/apps",
			Method:         http.MethodGet,
			Handler:        a.GetAllApps,
			ControllerName: a.Name(),
		},
	}
}

// Get all apps
func (a AppsController) GetAllApps(w http.ResponseWriter, r *http.Request) {
	apps, err := a.appRepo.GetAllApps()
	if err != nil {
		srverr.Handle500(w, err)
		return
	}

	err = json.NewEncoder(w).Encode(apps)
	if err != nil {
		srverr.Handle500(w, err)
		return
	}
}

var _ Controller = AppsController{}
