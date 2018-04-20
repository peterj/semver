package semver

import (
	"fmt"
	"strings"

	bsemver "github.com/blang/semver"
)

// VersionBump type represents which part of
// the version is being bumped
type VersionBump int

const (
	// Major version bump
	Major VersionBump = iota
	// Minor version bump
	Minor
	// Patch version bump
	Patch
)

// Bump bumps the provided version based on the version bump type
func Bump(version string, bump VersionBump) (string, error) {
	hasPrefix := strings.HasPrefix(version, "v")
	if hasPrefix {
		version = strings.TrimPrefix(version, "v")
	}

	parsedVersion, err := bsemver.Make(version)
	if err != nil {
		return "", fmt.Errorf("Invalid version provided")
	}

	switch bump {
	case Major:
		{
			parsedVersion.Major++
			break
		}
	case Minor:
		{
			parsedVersion.Minor++
			break
		}
	case Patch:
		{
			parsedVersion.Patch++
			break
		}
	}

	version = parsedVersion.String()
	if hasPrefix {
		version = "v" + version
	}
	return version, nil
}
