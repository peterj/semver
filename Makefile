include docker.mk 
NAME:=semver
PKG:=github.com/peterj/$(NAME)
GOOSARCHES=darwin/amd64

VERSION=$(shell cat ./VERSION.txt)
GITCOMMIT:=$(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES:=$(shell git status --porcelain --untracked-files=no)
ifneq ($(GITUNTRACKEDCHANGES),)
	GITCOMMIT := $(GITCOMMIT)-dirty
endif

# Sets the actual GITCOMMIT and VERSION values 
VERSION_INFO=-X $(PKG)/version.GITCOMMIT=$(GITCOMMIT) -X $(PKG)/version.VERSION=$(VERSION)

# Set the linker flags
GO_LDFLAGS=-ldflags "-w $(VERSION_INFO)"

all: build fmt lint test vet

# Builds the binary
.PHONY: build
build:
	@echo "-> $@"
	CGO_ENABLED=0 go build -i -installsuffix cgo ${GO_LDFLAGS} -o $(NAME) .

# Gofmt all code (sans vendor folder) just in case not using automatic formatting
.PHONY: fmt
fmt: 
	@echo "-> $@"
	@gofmt -s -l . | grep -v vendor | tee /dev/stderr

# Run golint
.PHONY: lint
lint:
	@echo "-> $@"
	@golint ./... | grep -v vendor | tee /dev/stderr

# Run all tests
.PHONY: test
test:
	@echo "-> $@"
	@go test -v $(shell go list ./... | grep -v vendor)

# Run govet
.PHONY: vet
vet:
	@echo "-> $@"
	@go vet $(shell go list ./... | grep -v vendor) | tee /dev/stderr

# Bumps the version of the service
.PHONY: bump-version
BUMP := patch
bump-version:
	$(eval NEW_VERSION = $(shell curl https://bump.semver.xyz/$(BUMP)?version=$(VERSION)))
	@echo "Bumping VERSION.txt from $(VERSION) to $(NEW_VERSION)"
	echo $(NEW_VERSION) > VERSION.txt
	git add VERSION.txt README.md
	git commit -vsam "Bump version to $(NEW_VERSION)"


# Builds and pushes the image, then upgrades the releases.
.PHONY: upgrade
upgrade:|bump-version publish.svc publish.web upgrade.svc upgrade.web
