package srverr

import (
	"golang-web-core/util"
	"net/http"
)

func Handle400(rw http.ResponseWriter, err error) {
	http.Error(rw, err.Error(), http.StatusBadRequest)
	util.LogColor("yellow", "BAD REQUEST: %v", err.Error())
}

func Handle401(rw http.ResponseWriter, err error) {
	http.Error(rw, err.Error(), http.StatusUnauthorized)
	util.LogColor("lightred", "UNAUTHORIZED: %v", err.Error())
}

func Handle403(rw http.ResponseWriter, err error) {
	http.Error(rw, err.Error(), http.StatusForbidden)
	util.LogColor("lightred", "FORBIDDEN: %v", err.Error())
}

func Handle404(rw http.ResponseWriter, err error) {
	http.Error(rw, err.Error(), http.StatusNotFound)
	util.LogColor("yellow", "NOT FOUND: %v", err.Error())
}

func Handle500(rw http.ResponseWriter, err error) {
	http.Error(rw, err.Error(), http.StatusInternalServerError)
	util.LogColor("red", "INTERNAL SERVER ERROR: %v", err.Error())
}

func HandleError(code int, rw http.ResponseWriter, err error) {
	http.Error(rw, err.Error(), code)
	util.LogColor("red", "%v: %v", code, err.Error())
}

func HandleSrvError(rw http.ResponseWriter, err error) {
	if srvErr, ok := err.(ServerError); ok {
		HandleError(srvErr.Code, rw, err)
	} else {
		Handle500(rw, err)
	}
}
