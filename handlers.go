package main

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gorilla/mux"
	"github.com/peterj/semver/pkg/semver"
)

// BumpHandler handles calls to the bump semver endpoint
func BumpHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("content-type", "application/json")
	v := mux.Vars(r)

	bumpType := v["type"]
	inputVersion := v["version"]

	result, err := semver.Bump(inputVersion, toVersionBump(bumpType))
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, result)
	return
}

func toVersionBump(bumpType string) semver.VersionBump {
	bumpType = strings.ToLower(bumpType)

	switch bumpType {
	case "major":
		{
			return semver.Major
		}
	case "minor":
		{
			return semver.Minor
		}
	case "patch":
		{
			return semver.Patch
		}
	}
	return semver.Patch
}
