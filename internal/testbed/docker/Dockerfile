# Copyright Dynatrace LLC
# SPDX-License-Identifier: Apache-2.0

# Image for the e2e tests. The build context is ./dist, which holds the
# collector_linux_<arch> binaries written by `make agent`.
FROM alpine:3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS certs
RUN apk --update add ca-certificates
# The collector writes ./logging.yaml if it can't find one, which fails on a
# read-only root filesystem. Ship one that logs to stdout instead.
RUN mkdir /etc/otel && printf 'output: stdout\nlevel: info\n' > /etc/otel/logging.yaml

FROM scratch

ARG TARGETARCH

USER 10001

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=certs /etc/otel/logging.yaml /etc/otel/logging.yaml
COPY --chmod=755 collector_linux_${TARGETARCH} /dynatrace-bindplane-otel-collector

# /etc/otel/manager.yaml does not exist, so the collector runs standalone
# instead of connecting to Bindplane.
ENV LOGGING_YAML_PATH=/etc/otel/logging.yaml
ENV MANAGER_YAML_PATH=/etc/otel/manager.yaml

ENTRYPOINT ["/dynatrace-bindplane-otel-collector"]
CMD ["--config", "/etc/otelcol/config.yaml"]
