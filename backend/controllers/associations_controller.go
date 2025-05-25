package controllers

import (
	"encoding/json"
	"golang-web-core/domain"
	"golang-web-core/srv/route"
	"golang-web-core/srv/srverr"
	"golang-web-core/util"
	"net/http"
	"reflect"
)

type AssociationsController struct {
	associationRepo domain.FileAssociationRepository
}

func NewAssociationsController(associationRepo domain.FileAssociationRepository) AssociationsController {
	return AssociationsController{associationRepo: associationRepo}
}

// BeforeAction implements Controller.
func (a AssociationsController) BeforeAction(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		handler(w, r)
	}
}

// Name implements Controller.
func (a AssociationsController) Name() string {
	return reflect.TypeOf(a).Name()
}

func (a AssociationsController) Routes() []route.Route {
	return []route.Route{
		{
			Pattern:        "/api/associations",
			Method:         http.MethodGet,
			Handler:        a.GetAllAssociations,
			ControllerName: a.Name(),
		},
		{
			Pattern:        "/api/associations",
			Method:         http.MethodPost,
			Handler:        a.CreateAssociation,
			ControllerName: a.Name(),
		},
		{
			Pattern:        "/api/associations/{id}",
			Method:         http.MethodDelete,
			Handler:        a.DeleteAssociation,
			ControllerName: a.Name(),
		},
	}
}

// Get all associations
func (a AssociationsController) GetAllAssociations(w http.ResponseWriter, r *http.Request) {
	associations, err := a.associationRepo.GetAllAssociations()
	if err != nil {
		srverr.Handle500(w, err)
		return
	}

	err = json.NewEncoder(w).Encode(associations)
	if err != nil {
		srverr.Handle500(w, err)
		return
	}
}

// Create an association
func (a AssociationsController) CreateAssociation(w http.ResponseWriter, r *http.Request) {
	var association domain.FileAssociation
	err := util.DecodeContextParams(r, &association)
	if err != nil {
		srverr.Handle400(w, err)
		return
	}

	association, err = a.associationRepo.CreateAssociation(association)
	if err != nil {
		srverr.Handle500(w, err)
		return
	}

	err = json.NewEncoder(w).Encode(association)
	if err != nil {
		srverr.Handle500(w, err)
		return
	}
}

// Delete an association
func (a AssociationsController) DeleteAssociation(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")

	err := a.associationRepo.DeleteAssociation(id)
	if err != nil {
		srverr.Handle500(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

var _ Controller = AssociationsController{}
