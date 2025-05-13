package srv

import (
	"golang-web-core/util"
	"net/http"
)

type FileServer struct {
	http.Handler
	Prefix string
}

func (s FileServer) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	util.LogItalicColor("lightgray", "Serving %v%v to %v", s.Prefix, req.URL.Path, req.RemoteAddr)
	s.Handler.ServeHTTP(rw, req)
}
