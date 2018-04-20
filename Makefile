PREFIX?=$(shell pwd)
NAME := semver
PKG := github.com/peterj/$(NAME)

GOOSARCHES = darwin/amd64
BUILDDIR := ${PREFIX}/release

VERSION = $(shell cat ./VERSION.txt)
GITCOMMIT := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
ifneq ($(GITUNTRACKEDCHANGES),)
	GITCOMMIT := $(GITCOMMIT)-dirty
endif

# Sets the GITCOMMIT and VERSION
CTIMEVAR=-X $(PKG)/version.GITCOMMIT=$(GITCOMMIT) -X $(PKG)/version.VERSION=$(VERSION)
GO_LDFLAGS=-ldflags "-w $(CTIMEVAR)"

# Docker settings
REGISTRY_NAME := peterjreg.azurecr.io
SVC_DOCKERFILE := Dockerfile.svc
SVC_IMAGE_NAME =$(REGISTRY_NAME)/$(NAME):$(VERSION)

WEB_DOCKERFILE := Dockerfile.web
WEB_IMAGE_NAME = $(REGISTRY_NAME)/semver-web:0.1.0

all: clean build fmt lint test vet install

.PHONY: build
build: $(NAME)

$(NAME): *.go VERSION.txt
	@echo "-> $@"
	CGO_ENABLED=0 go build -i -installsuffix cgo ${GO_LDFLAGS} -o $(NAME) .

.PHONY: clean
clean:
	@echo "-> $@"
	$(RM) $(NAME)
	$(RM) -r $(BUILDDIR)

.PHONY: fmt
fmt: ## Verifies all files have men `gofmt`ed
	@echo "-> $@"
	@gofmt -s -l . | grep -v '.pb.go:' | grep -v vendor | tee /dev/stderr

.PHONY: lint
lint: ## Verifies `golint` passes
	@echo "-> $@"
	@golint ./... | grep -v '.pb.go:' | grep -v vendor | tee /dev/stderr

.PHONY: test
test: ## Runs the go tests
	@echo "-> $@"
	@go test -v -tags "$(BUILDTAGS) cgo" $(shell go list ./... | grep -v vendor)

.PHONY: vet
vet: ## Verifies `go vet` passes
	@echo "-> $@"
	@go vet $(shell go list ./... | grep -v vendor) | grep -v '.pb.go:' | tee /dev/stderr

.PHONY: install
install: ## Installs the executable or package
	@echo "-> $@"
	go install -a -tags "$(BUILDTAGS)" ${GO_LDFLAGS} .

# Builds a docker image
define build_image
	docker build -f $(1) -t $(2) .
endef

# Pushes a docker image
define push_image
	docker push $(1)
endef

.PHONY: build.image.svc
build.image.svc:
	@echo "-> $@"
	$(call build_image, $(SVC_DOCKERFILE), $(SVC_IMAGE_NAME))

.PHONY: build.image.web
build.image.web:
	@echo "-> $@"
	$(call build_image, $(WEB_DOCKERFILE), $(WEB_IMAGE_NAME))

.PHONY: push.image.svc
push.image.svc:
	@echo "-> $@"
	$(call push_image, $(SVC_IMAGE_NAME))

.PHONY: push.image.web
push.image.web:
	@echo "-> $@"
	$(call push_image, $(WEB_IMAGE_NAME))

.PHONY: publish.svc
publish.svc: build.image.svc push.image.svc

.PHONY: publish.web
publish.web: build.image.web push.image.web

KUBE_NAMESPACE := semverservice
RELEASE_NAME := prod

.PHONY: install.svc
install.svc:
	@echo "-> $@"
	helm install --name $(RELEASE_NAME) --namespace $(KUBE_NAMESPACE) --set=image.tag=$(VERSION) helm/semver-svc

define bump_version
	curl https://bump.semver.xyz/minor?version=$(VERSION)
endef

.PHONY: bump-version
BUMP := patch
bump-version:
	$(eval NEW_VERSION = $(shell curl https://bump.semver.xyz/$(BUMP)?version=$(VERSION)))
	@echo "Bumping VERSION.txt from $(VERSION) to $(NEW_VERSION)"
	echo $(NEW_VERSION) > VERSION.txt
	git add VERSION.txt README.md
	git commit -vsam "Bump version to $(NEW_VERSION)"

# Builds and pushes the image, then upgrades the release.
upgrade: bump-version publish.svc upgrade.svc

.PHONY: upgrade.svc
upgrade.svc:
	@echo "-> $@"
	helm upgrade $(RELEASE_NAME) --namespace $(KUBE_NAMESPACE) --set=image.tag=$(VERSION) helm/semver-svc