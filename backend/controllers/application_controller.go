package controllers

import (
	"fmt"
	"golang-web-core/domain"
	apprepo "golang-web-core/repositories/app"
	fileassociationrepo "golang-web-core/repositories/file_association"
	"golang-web-core/srv/cfg"
	"golang-web-core/util"
	"net/http"
	"reflect"
)

// you shouldn't be touching this file except for the BeforeAction and setupControllers

type ApplicationController struct {
	cfg.Config
	Controllers     map[string]Controller
	appRepo         domain.AppRepository
	associationRepo domain.FileAssociationRepository
}

// this verifies that ApplicationController fully implements Controller
var ApplicationControllerVerifier Controller = ApplicationController{}

func NewApplicationController(config cfg.Config) (ApplicationController, error) {
	cont := ApplicationController{
		Config:      config,
		Controllers: map[string]Controller{},
	}

	err := cont.setupRepositories()
	if err != nil {
		return ApplicationController{}, err
	}

	err = cont.setupControllers()
	if err != nil {
		return ApplicationController{}, err
	}

	return cont, err
}

func (c ApplicationController) Name() string {
	return reflect.TypeOf(c).Name()
}

func (c ApplicationController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(rw http.ResponseWriter, req *http.Request) {
		// any checks you want to do on every single request that goes into the server can go here

		// this line initiates the next step in the request process.
		// if you wanted to throw an error here or something, it might look something like this:
		// if (someCondition) {
		// 	http.Error(rw, "This is a test internal server error", http.StatusInternalServerError)
		// 	return
		// }
		handler(rw, req)
	}
}

func (c ApplicationController) Favicon(rw http.ResponseWriter, req *http.Request) {
	http.ServeFile(rw, req, "favicon.ico")
}

func (c *ApplicationController) setupRepositories() error {
	switch c.Config.AppRepository.Type {
	case "MockAppRepository":
		c.appRepo = apprepo.MockAppRepository{}
	default:
		return fmt.Errorf("unknown app repository type: %v", c.Config.AppRepository.Type)
	}

	switch c.Config.FileAssociationRepository.Type {
	case "MockFileAssociationRepository":
		c.associationRepo = fileassociationrepo.MockFileAssociationRepository{}
	default:
		return fmt.Errorf("unknown file association repository type: %v", c.Config.FileAssociationRepository.Type)
	}

	return nil
}

func (c *ApplicationController) setupControllers() error {
	controllers := []Controller{
		c,
		// this is where you initialize your controllers. if you do not initialize your controllers here, they will not be usable
		NewAppsController(c.appRepo),
		NewAssociationsController(c.associationRepo),
	}

	// everything below here should be left untouched

	for _, cont := range controllers {
		_, ok := c.Controllers[cont.Name()]
		if ok {
			return fmt.Errorf("error: a controller with the name %v was registered twice", cont.Name())
		}
		c.Controllers[cont.Name()] = cont
	}

	return nil
}

func (c ApplicationController) GetController(name string) Controller {
	controller, ok := c.Controllers[name]
	if !ok {
		util.LogFatalf("attempted to access a controller that does not exist! %v; please add it to ApplicationController.setupControllers", name)
	}

	return controller
}
