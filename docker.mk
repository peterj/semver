
VERSION=$(shell cat ./VERSION.txt)

# Kubernetes namespace where services will be installed
KUBE_NAMESPACE:=semverservice

# Name of the release used with Helm 
RELEASE_NAME:=prod

# Helm chart names
SVC_HELM_CHART:=helm/semver-svc
WEB_HELM_CHART:=helm/semver-web

# Docker settings (make sure DOCKER_REGISTRY environment variable is set)
SVC_NAME=semver-svc
REGISTRY_NAME:=$(DOCKER_REGISTRY)
SVC_DOCKERFILE:=Dockerfile.svc
SVC_IMAGE_NAME=$(REGISTRY_NAME)/$(SVC_NAME):$(VERSION)

WEB_NAME=semver-web
WEB_DOCKERFILE:=Dockerfile.web
WEB_IMAGE_NAME=$(REGISTRY_NAME)/$(WEB_NAME):$(VERSION)

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

# Installs a new Helm chart
define helm_install
	helm install --name $(1) --namespace $(2) --set=image.repository=$(3) --set=image.tag=$(4) $(5)
endef

# Upgrades an existing Helm chart
define helm_upgrade
	helm upgrade $(1) --namespace $(2) --set=image.repository=$(3) --set=image.tag=$(4) $(5)
endef


.PHONY: install.svc
install.svc:
	@echo "-> $@"
	$(call helm_install,$(RELEASE_NAME)-svc,$(KUBE_NAMESPACE),$(REGISTRY_NAME)/$(SVC_NAME),$(VERSION),$(SVC_HELM_CHART))

.PHONY: install.web
install.web:
	@echo "-> $@"
	$(call helm_install,$(RELEASE_NAME)-web,$(KUBE_NAMESPACE),$(REGISTRY_NAME)/$(WEB_NAME),$(VERSION),$(WEB_HELM_CHART))


.PHONY: upgrade.svc
upgrade.svc:
	@echo "-> $@"
	$(call helm_upgrade,$(RELEASE_NAME)-svc,$(KUBE_NAMESPACE),$(REGISTRY_NAME)/$(SVC_NAME),$(VERSION),$(SVC_HELM_CHART))

.PHONY: upgrade.web
upgrade.web:
	@echo "-> $@"
	$(call helm_upgrade,$(RELEASE_NAME)-web,$(KUBE_NAMESPACE),$(REGISTRY_NAME)/$(WEB_NAME),$(VERSION),$(WEB_HELM_CHART))