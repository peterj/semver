package main

import (
	"net/http"

	"github.com/gorilla/mux"
)

// NewRouter creates a new mux Router
func NewRouter() *mux.Router {
	router := mux.NewRouter().StrictSlash(true)
	withLogger := func(handler http.HandlerFunc, name string) http.Handler {
		return Logger(handler, name)
	}

	router.Methods("GET").
		Path("/{type}").
		Name("bump").
		Queries("version", "{version}").
		Handler(withLogger(BumpHandler, "bump"))

	return router
}
