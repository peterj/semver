# semver

### Initial deployment to Kubernetes

If you're starting from a clean Kubernetes cluster (or namespaces), you will
have to install `kube-lego` and `nginx-ingress`

```
helm install stable/kube-lego \
 --set config.LEGO_EMAIL=[YOUR_EMAIL] \
 --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory

helm install stable/nginx-ingress --namespace [NAMESPACE]
```

Once those are installed you can run `make install.svc` to install the semver
service.

#### Upgrades while developing

If you already have an existing Helm release, you can use `make upgrade` to
build the service Docker image, push it to the registry and upgrade the existing
release in Kubernetes.

TBD: Bumping versions.
