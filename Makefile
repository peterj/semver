PREFIX?=$(shell pwd)
NAME := semver
PKG := github.com/peterj/$(NAME)

GOOSARCHES = darwin/amd64
BUILDDIR := ${PREFIX}/release

VERSION := $(shell cat ./VERSION.txt)
GITCOMMIT := $(shell git rev-parse --short HEAD)
GITUNTRACKEDCHANGES := $(shell git status --porcelain --untracked-files=no)
ifneq ($(GITUNTRACKEDCHANGES),)
	GITCOMMIT := $(GITCOMMIT)-dirty
endif

# Sets the GITCOMMIT and VERSION
CTIMEVAR=-X $(PKG)/version.GITCOMMIT=$(GITCOMMIT) -X $(PKG)/version.VERSION=$(VERSION)
GO_LDFLAGS=-ldflags "-w $(CTIMEVAR)"

REGISTRY_NAME = peterjreg.azurecr.io
IMAGE_NAME = $(REGISTRY_NAME)/$(NAME):$(VERSION)

all: clean build fmt lint test vet install

.PHONY: build
build: $(NAME)

$(NAME): *.go VERSION.txt
	@echo "+ $@"
	CGO_ENABLED=0 go build -i -installsuffix cgo ${GO_LDFLAGS} -o $(NAME) .

build.image:
	docker build -t $(IMAGE_NAME) .

.PHONY: clean
clean:
	@echo "+ $@"
	$(RM) $(NAME)
	$(RM) -r $(BUILDDIR)

.PHONY: fmt
fmt: ## Verifies all files have men `gofmt`ed
	@echo "+ $@"
	@gofmt -s -l . | grep -v '.pb.go:' | grep -v vendor | tee /dev/stderr

.PHONY: lint
lint: ## Verifies `golint` passes
	@echo "+ $@"
	@golint ./... | grep -v '.pb.go:' | grep -v vendor | tee /dev/stderr

.PHONY: test
test: ## Runs the go tests
	@echo "+ $@"
	@go test -v -tags "$(BUILDTAGS) cgo" $(shell go list ./... | grep -v vendor)

.PHONY: vet
vet: ## Verifies `go vet` passes
	@echo "+ $@"
	@go vet $(shell go list ./... | grep -v vendor) | grep -v '.pb.go:' | tee /dev/stderr

.PHONY: install
install: ## Installs the executable or package
	@echo "+ $@"
	go install -a -tags "$(BUILDTAGS)" ${GO_LDFLAGS} .

.PHONY: release.aci
release.aci: ## pushes a new instance to container instances 
	RESOURCE_GROUP := semverservice
	PORT := 8080
	DNS_NAME := semverservice
	REGISTRY_USER := peterjreg
	REGISTRY_PASSWORD := todo
	az container create --resource-group $(RESOURCE_GROUP) --name $(DNS_NAME) --image $(IMAGE_NAME) --ports $(PORT) --dns-name-label $(DNS_NAME) --registry-login-server $(REGISTRY_NAME) --registry-username $(REGISTRY_USER) --registry-password $(REGISTRY_PASSWORD)

.PHONY: push
push: 
	docker push $(IMAGE_NAME)

.PHONY: publish
publish: build.image push

.PHONY: deploy
deploy:
	kubectl apply -f kube/deploy.yaml

restart:
	kubectl delete po -l app=$(NAME) -n semverservice
