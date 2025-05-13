package srv

import (
	"context"
	"golang-web-core/controllers"
	"golang-web-core/srv/cfg"
	"golang-web-core/srv/route"
	"golang-web-core/util"
	"log"
	"math/rand"
	"net/http"
	"time"
)

func generateRequestID(length int) string {
	rand.New(rand.NewSource(time.Now().UnixNano())) // Seed for randomness
	const chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	result := make([]byte, length)
	for i := 0; i < length; i++ {
		result[i] = chars[rand.Intn(len(chars))]
	}
	return string(result)
}

func SetRequestID(req *http.Request) {
	requestId := generateRequestID(16)

	req.Header.Set("X-Request-ID", requestId)
}

func HandleRequest(appController controllers.ApplicationController, route route.Route) http.HandlerFunc {
	return func(rw http.ResponseWriter, req *http.Request) {
		SetRequestID(req)

		logRequest(req)

		params, err := util.GetParams(req)
		if err == nil {
			if appController.Config.Env == cfg.Development {
				log.Printf("%v Params: %v\n", req.Header.Get("X-Request-ID"), params)
			}
		}
		if params == nil {
			params = map[string]any{}
		}

		reqWithParams := req.WithContext(context.WithValue(req.Context(), util.ParamsKey, params))

		controller := appController.Controllers[route.ControllerName]

		appController.BeforeAction(controller.BeforeAction(route.Handler))(rw, reqWithParams)

		logFinished(rw, reqWithParams)
	}
}

func HandleOptions(rw http.ResponseWriter, req *http.Request) {
	rw.Header().Set("Access-Control-Allow-Origin", "*")
	rw.Header().Set("Access-Control-Allow-Methods", "*")
	rw.Header().Set("Access-Control-Allow-Headers", "*")
	rw.WriteHeader(http.StatusOK)
}

func logRequest(req *http.Request) {
	color := "255;255;255"

	switch req.Method {
	case http.MethodGet:
		color = "0;0;255"
	case http.MethodConnect:
		color = "0;0;255"
	case http.MethodOptions:
		color = "0;0;255"
	case http.MethodTrace:
		color = "0;0;255"
	case http.MethodPost:
		color = "100;255;100"
	case http.MethodPatch:
		color = "255;255;0"
	case http.MethodPut:
		color = "255;255;0"
	case http.MethodDelete:
		color = "255;0;0"
	}

	requestID := req.Header.Get("X-Request-ID")
	log.Printf("%v Started \033[38;2;%vm%v\033[0m %v for %v\n", requestID, color, req.Method, req.URL.Path, req.RemoteAddr)
}

func logFinished(rw http.ResponseWriter, req *http.Request) {
	requestID := req.Header.Get("X-Request-ID")

	if rw.Header().Get("Content-Type") == "text/plain; charset=utf-8" {
		log.Printf("%v %v %v finished with error, remote address: %v\n", requestID, req.Method, req.URL.Path, req.RemoteAddr)
	} else {
		log.Printf("%v Finished %v %v for %v\n", requestID, req.Method, req.URL.Path, req.RemoteAddr)
	}
}
