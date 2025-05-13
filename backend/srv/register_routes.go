package srv

import (
	"fmt"
	"golang-web-core/controllers"
	"net/http"
	"slices"
)

func (s *Server) RegisterRoutes() error {
	appController, err := controllers.NewApplicationController(s.Config)
	if err != nil {
		return err
	}
	routes := s.Router.Routes(appController)

	registeredPatterns := []string{}

	for _, route := range routes {
		_, ok := s.Routes[route.Method+" "+route.Pattern]
		if ok {
			return fmt.Errorf("error: route pattern %v %v was registered twice", route.Method, route.Pattern)
		}
		s.Routes[route.Method+" "+route.Pattern] = route

		s.Mux.HandleFunc(fmt.Sprintf("%v %v", route.Method, route.Pattern), HandleRequest(appController, route))
		patternRegistered := slices.Contains(registeredPatterns, route.Pattern)
		if !patternRegistered {
			s.Mux.HandleFunc(fmt.Sprintf("%v %v", http.MethodOptions, route.Pattern), http.HandlerFunc(HandleOptions))
		}

		registeredPatterns = append(registeredPatterns, route.Pattern)
	}

	if s.Config.PublicFS {
		s.Mux.Handle("GET /public/", http.StripPrefix("/public/", FileServer{Prefix: "/public/", Handler: http.FileServer(http.Dir("public"))}))
	}

	return nil
}
