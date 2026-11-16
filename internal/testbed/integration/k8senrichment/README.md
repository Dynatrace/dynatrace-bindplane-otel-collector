# Enrich from Kubernetes

This is the e2e test for the Collector use-case:
[Enrich from Kubernetes](https://docs.dynatrace.com/docs/shortlink/otel-collector-cases-k8s-enrich).

## Requirements to run the tests

- Docker or Podman
- Kind

The tests require a running Kind k8s cluster. During the tests,
a Dynatrace distribution of the OpenTelemetry Collector is deployed
on the k8s cluster with configurations as per the Dynatrace documentation page.

Traces are generated and sent to the Collector, which then
exports to the test where the k8s attributes are asserted on the
received traces.

## Running the tests locally

To execute the tests locally, follow these steps:

### Start a `kind` cluster

To create a new cluster, execute the following command:

```shell
kind create cluster
```
### Build the collector binary and the container

Fetch the config examples, build the Linux collector binary and build the e2e images from the repository root:

```shell
make e2e-config-examples
GOOS=linux GOARCH=amd64 make agent
make e2e-images E2E_IMAGE_ARCH=amd64
```

Use the architecture of your `kind` nodes, which on Apple silicon is `arm64`. The images are tagged
`dynatrace-bindplane-otel-collector:e2e-test` and `dynatrace-bindplane-otel-collector-journald:e2e-test`.

Load the image into the `kind` cluster.

**With `docker`:**
```shell
kind load docker-image dynatrace-bindplane-otel-collector:e2e-test --name kind
```

**With `podman`:**
```shell
podman save -o dynatrace-bindplane-otel-collector.tar dynatrace-bindplane-otel-collector:e2e-test
kind load image-archive dynatrace-bindplane-otel-collector.tar --name kind
```

### Running the tests

After the above steps are completed, the E2E tests can be run.

Note that the tests will, by default, use the following `kubeconfig` path: `/tmp/kube-config-collector-e2e-testing`.
This path can be modified by setting the `KUBECONFIG` environment variable (in case you have a local kind cluster with the
kube config located in `~/.kube.config`).
Also, if you are using `podman`, the collector image will be prefixed with `localhost/` within the local
`kind` registry. In this case, you will need to set the `CONTAINER_REGISTRY` to `localhost/`.
When using `docker`, setting the `CONTAINER_REGISTRY` env var is not required.
Below are the commands to execute the `k8senrichment` e2e test:

** Using podman:**
```shell
cd internal/testbed/integration/k8senrichment
KUBECONFIG="~/.kube/config" CONTAINER_REGISTRY="localhost/" go test -v --tags=e2e
```

** Using docker:**
```shell
cd internal/testbed/integration/k8senrichment
KUBECONFIG="/Users/my-user/.kube/config" go test -v --tags=e2e
```


