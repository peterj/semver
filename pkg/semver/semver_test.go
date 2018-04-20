package semver_test

import (
	"testing"

	"github.com/peterj/semver/pkg/semver"
)

const succeeded = "\u2713"
const failed = "\u2717"

func TestSemverBump(t *testing.T) {
	tt := []struct {
		name           string
		input          string
		expectedOutput string
		bump           semver.VersionBump
	}{
		{
			name:           "major bump",
			input:          "1.0.0",
			expectedOutput: "2.0.0",
			bump:           semver.Major,
		},
		{
			name:           "minor bump",
			input:          "1.0.0",
			expectedOutput: "1.1.0",
			bump:           semver.Minor,
		},
		{
			name:           "patch bump",
			input:          "1.0.0",
			expectedOutput: "1.0.1",
			bump:           semver.Patch,
		},
		{
			name:           "major bump with 'v'",
			input:          "v1.0.0",
			expectedOutput: "v2.0.0",
			bump:           semver.Major,
		},
		{
			name:           "minor bump with 'v'",
			input:          "v1.0.0",
			expectedOutput: "v1.1.0",
			bump:           semver.Minor,
		},
		{
			name:           "patch bump with 'v'",
			input:          "v1.0.0",
			expectedOutput: "v1.0.1",
			bump:           semver.Patch,
		},
		{
			name:           "major bump with pre and build",
			input:          "1.0.0-beta.preview+123.mybuild",
			expectedOutput: "2.0.0-beta.preview+123.mybuild",
			bump:           semver.Major,
		},
	}

	t.Log("Given the need to test semver bump.")
	{
		for i, tst := range tt {
			t.Logf("\tTest %d: \t%s", i, tst.name)
			{
				output, err := semver.Bump(tst.input, tst.bump)
				if err != nil {
					t.Fatalf("\t%s\tShould not have failed : got[%d]\n", failed, err)
				}

				if output != tst.expectedOutput {
					t.Fatalf("\t%s\tShould have the correct output : exp[%s] got[%s]\n", failed, tst.expectedOutput, output)
				}
				t.Logf("\t%s\tShould have the correct output\n", succeeded)
			}
		}
	}
}

func TestSemverBumpErrors(t *testing.T) {
	tt := []struct {
		name  string
		input string
		bump  semver.VersionBump
	}{
		{
			name:  "invalid version",
			input: "blah",
			bump:  semver.Major,
		},
		{
			name:  "uppercase prefix V",
			input: "V1.0.0",
			bump:  semver.Major,
		},
	}
	t.Log("Given the need to test errors from semver bump.")
	{
		for i, tst := range tt {
			t.Logf("\tTest %d: \t%s", i, tst.name)
			{
				_, err := semver.Bump(tst.input, tst.bump)
				if err == nil {
					t.Fatalf("\t%s\tShould have failed\n", failed)
				}
				t.Logf("\t%s\tShould have failed\n", succeeded)
			}
		}
	}
}
