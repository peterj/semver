# Semantic versioning service

[![Go Report Card](https://goreportcard.com/badge/github.com/peterj/semver?style=flat-square)](https://goreportcard.com/report/github.com/peterj/semver)

This repo contains a simple service that allows you to bump semantic version.
You give it a version and a type of bump you want (major, minor, patch) and it
will return you the updated version string.

Running version of the service is a https://www.semver.xyz and you can read more
about it on
[Medium](https://medium.com/@pjausovec/from-makefile-to-go-semantic-versioning-service-on-kubernetes-3fae678db87c).

### Build and run locally

Run `make all` to build (and run) service locally. `all` will run go format,
linter, tests and go vet.

### Docker build and push

Before running the commands below, make sure you set the `DOCKER_REGISTRY`
environment variable to the name of your Docker registry.

Build the Docker image for the service and push it to the registry :

```bash
make publish.svc
```

Build Docker image for the web:

```bash
make publish.web
```

There are also targets for only building and only pushing the images. Use
`make build.image.svc` or `make push.image.svc` to build and push the images
separately.

### Initial deployment to Kubernetes

If you're starting from a clean Kubernetes cluster (or namespaces), you will
have to install `kube-lego` and `nginx-ingress` first:

```bash
helm install stable/kube-lego \
 --set config.LEGO_EMAIL=[YOUR_EMAIL] \
 --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory
```

Install Nginx ingress:

```bash
helm install stable/nginx-ingress --namespace [NAMESPACE]
```

Once those are installed you can run `make install.svc` to install the semver
service and `make install.web` to install the web portion of the project.

#### Incremental upgrades

If you already have an existing Helm release (i.e. you did the initial
deployment to Kubernetes), you can use `make upgrade` command to build the
Docker images, push them to the registry and upgrade the existing releases that
are running inside Kubernetes.
