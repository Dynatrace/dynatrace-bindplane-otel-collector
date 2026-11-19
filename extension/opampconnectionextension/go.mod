module github.com/dynatrace/dynatrace-bindplane-otel-collector/extension/opampconnectionextension

go 1.26.10

require (
	github.com/dynatrace/dynatrace-bindplane-otel-collector/pkg/report v1.3.1
	github.com/dynatrace/dynatrace-bindplane-otel-contrib/extension/pebbleextension v1.3.0
	github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/measurements v1.3.0
	github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/osinfo v1.3.0
	github.com/dynatrace/dynatrace-bindplane-otel-contrib/processor/topologyprocessor v1.3.0
	github.com/golang/snappy v1.0.0
	github.com/google/uuid v1.6.0
	github.com/oklog/ulid/v2 v2.1.2
	github.com/open-telemetry/opamp-go v0.25.0
	github.com/open-telemetry/opentelemetry-collector-contrib/confmap/provider/aesprovider v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/connector/spanmetricsconnector v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/exporter/prometheusexporter v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/exporter/prometheusremotewriteexporter v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/extension/encoding/awslogsencodingextension v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/extension/opampcustommessages v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/golden v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/pdatatest v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/translator/jaeger v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/translator/zipkin v0.165.1
	github.com/open-telemetry/opentelemetry-collector-contrib/receiver/filelogreceiver v0.165.1
	github.com/spf13/pflag v1.1.0
	github.com/stretchr/testify v1.12.1
	go.opentelemetry.io/collector/component v1.71.0
	go.opentelemetry.io/collector/confmap v1.71.0
	go.opentelemetry.io/collector/confmap/provider/envprovider v1.71.0
	go.opentelemetry.io/collector/confmap/provider/fileprovider v1.71.0
	go.opentelemetry.io/collector/confmap/provider/httpsprovider v1.71.0
	go.opentelemetry.io/collector/confmap/provider/yamlprovider v1.71.0
	go.opentelemetry.io/collector/consumer v1.71.0
	go.opentelemetry.io/collector/exporter v1.71.0
	go.opentelemetry.io/collector/exporter/nopexporter v0.165.0
	go.opentelemetry.io/collector/extension v1.71.0
	go.opentelemetry.io/collector/featuregate v1.71.0
	go.opentelemetry.io/collector/otelcol v0.165.0
	go.opentelemetry.io/collector/pdata v1.71.0
	go.opentelemetry.io/collector/receiver v1.71.0
	go.opentelemetry.io/collector/service v0.165.0
	go.opentelemetry.io/otel/sdk/metric v1.47.0
	go.uber.org/zap v1.28.0
	golang.org/x/exp v0.0.0-20260908205506-85c1c2202aba
	golang.org/x/sys v0.50.0
	gopkg.in/natefinch/lumberjack.v2 v2.2.1
	gopkg.in/yaml.v3 v3.0.1
)

require (
	cloud.google.com/go/auth v0.23.2 // indirect
	cloud.google.com/go/auth/oauth2adapt v0.2.8 // indirect
	cloud.google.com/go/compute/metadata v0.10.0 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/azcore v1.23.1 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/azidentity v1.14.1 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/internal v1.12.0 // indirect
	github.com/AzureAD/microsoft-authentication-library-for-go v1.8.0 // indirect
	github.com/DataDog/zstd v1.5.7 // indirect
	github.com/Microsoft/go-winio v0.6.4 // indirect
	github.com/alecthomas/units v0.0.0-20240927000941-0f3dac36c52b // indirect
	github.com/andybalholm/brotli v1.2.7 // indirect
	github.com/apache/thrift v0.25.0 // indirect
	github.com/aws/aws-lambda-go v1.55.1 // indirect
	github.com/aws/aws-sdk-go-v2 v1.47.1 // indirect
	github.com/aws/aws-sdk-go-v2/config v1.33.6 // indirect
	github.com/aws/aws-sdk-go-v2/credentials v1.20.6 // indirect
	github.com/aws/aws-sdk-go-v2/feature/ec2/imds v1.20.1 // indirect
	github.com/aws/aws-sdk-go-v2/internal/configsources v1.5.4 // indirect
	github.com/aws/aws-sdk-go-v2/internal/endpoints/v2 v2.8.4 // indirect
	github.com/aws/aws-sdk-go-v2/internal/v4a v1.5.4 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/accept-encoding v1.13.19 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/presigned-url v1.14.4 // indirect
	github.com/aws/aws-sdk-go-v2/service/signin v1.10.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/sso v1.38.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/ssooidc v1.43.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/sts v1.51.1 // indirect
	github.com/aws/smithy-go v1.28.2 // indirect
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/bmatcuk/doublestar/v4 v4.10.4 // indirect
	github.com/brunoscheufler/aws-ecs-metadata-go v0.0.0-20221221133751-67e37ae746cd // indirect
	github.com/cenkalti/backoff/v4 v4.3.0 // indirect
	github.com/cenkalti/backoff/v5 v5.0.3 // indirect
	github.com/cenkalti/backoff/v7 v7.0.3 // indirect
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/cockroachdb/errors v1.11.3 // indirect
	github.com/cockroachdb/fifo v0.0.0-20240606204812-0bbfbd93a7ce // indirect
	github.com/cockroachdb/logtags v0.0.0-20230118201751-21c54148d20b // indirect
	github.com/cockroachdb/pebble v1.1.5 // indirect
	github.com/cockroachdb/redact v1.1.5 // indirect
	github.com/cockroachdb/tokenbucket v0.0.0-20230807174530-cc333fc44b06 // indirect
	github.com/davecgh/go-spew v1.1.2-0.20180830191138-d8f796af33cc // indirect
	github.com/dennwc/varint v1.0.0 // indirect
	github.com/dynatrace/dynatrace-bindplane-otel-contrib/pkg/snapshot v1.3.1-0.20261116155315-80fc01d0d900 // indirect
	github.com/ebitengine/purego v0.11.2 // indirect
	github.com/elastic/lunes v0.2.2 // indirect
	github.com/elastic/proxy-connect-dialer-go v0.1.1 // indirect
	github.com/expr-lang/expr v1.17.8 // indirect
	github.com/felixge/httpsnoop v1.1.0 // indirect
	github.com/foxboron/go-tpm-keyfiles v0.0.0-20260902202739-8c9c2d1005f4 // indirect
	github.com/fxamacker/cbor/v2 v2.9.4 // indirect
	github.com/getsentry/sentry-go v0.27.0 // indirect
	github.com/go-logr/logr v1.4.4 // indirect
	github.com/go-logr/stdr v1.2.2 // indirect
	github.com/go-ole/go-ole v1.3.0 // indirect
	github.com/go-viper/mapstructure/v2 v2.5.0 // indirect
	github.com/gobwas/glob v0.2.3 // indirect
	github.com/goccy/go-json v0.10.6 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang-jwt/jwt/v5 v5.3.1 // indirect
	github.com/google/go-tpm v0.9.9-0.20260124013517-8f8f42cba0de // indirect
	github.com/google/s2a-go v0.1.9 // indirect
	github.com/googleapis/enterprise-certificate-proxy v0.3.20 // indirect
	github.com/googleapis/gax-go/v2 v2.24.0 // indirect
	github.com/gorilla/websocket v1.5.4-0.20250319132907-e064f32e3674 // indirect
	github.com/grafana/regexp v0.0.0-20250905093917-f7b3be9d1853 // indirect
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.31.0 // indirect
	github.com/hashicorp/go-version v1.9.0 // indirect
	github.com/hashicorp/golang-lru/v2 v2.0.7 // indirect
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/jaegertracing/jaeger-idl v0.14.0 // indirect
	github.com/jonboulle/clockwork v0.5.0 // indirect
	github.com/jpillora/backoff v1.1.0 // indirect
	github.com/json-iterator/go v1.1.12 // indirect
	github.com/klauspost/compress v1.20.3 // indirect
	github.com/knadh/koanf/maps v0.1.3 // indirect
	github.com/knadh/koanf/providers/confmap v1.0.1 // indirect
	github.com/knadh/koanf/v2 v2.4.1 // indirect
	github.com/kr/pretty v0.3.1 // indirect
	github.com/kr/text v0.2.0 // indirect
	github.com/kylelemons/godebug v1.1.0 // indirect
	github.com/leodido/go-syslog/v4 v4.6.0 // indirect
	github.com/leodido/ragel-machinery v0.0.0-20190525184631-5f46317e436b // indirect
	github.com/lightstep/go-expohisto v1.0.0 // indirect
	github.com/lufia/plan9stats v0.0.0-20260330125221-c963978e514e // indirect
	github.com/magefile/mage v1.15.0 // indirect
	github.com/mitchellh/copystructure v1.2.0 // indirect
	github.com/mitchellh/reflectwalk v1.0.2 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.3-0.20250322232337-35a7c28c31ee // indirect
	github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822 // indirect
	github.com/mwitkow/go-conntrack v0.0.0-20190716064945-2f068394615f // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/extension/encoding v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/internal/coreinternal v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/internal/pdatautil v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/core/xidutils v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/resourcetotelemetry v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/sampling v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/stanza v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/translator/prometheus v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/translator/prometheusremotewrite v0.165.1 // indirect
	github.com/open-telemetry/opentelemetry-collector-contrib/pkg/xstreamencoding v0.165.1 // indirect
	github.com/openzipkin/zipkin-go v0.4.3 // indirect
	github.com/parquet-go/bitpack v1.0.0 // indirect
	github.com/parquet-go/jsonlite v1.0.0 // indirect
	github.com/parquet-go/parquet-go v0.32.0 // indirect
	github.com/pierrec/lz4/v4 v4.1.33 // indirect
	github.com/pkg/browser v0.0.0-20240102092130-5ac0b6a4141c // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/power-devops/perfstat v0.0.0-20260805114148-88456608a4f6 // indirect
	github.com/prometheus/client_golang v1.25.0 // indirect
	github.com/prometheus/client_golang/exp v0.0.0-20260907100614-57bb367da472 // indirect
	github.com/prometheus/client_model v0.6.3 // indirect
	github.com/prometheus/common v0.72.1 // indirect
	github.com/prometheus/otlptranslator v1.0.0 // indirect
	github.com/prometheus/procfs v0.22.0 // indirect
	github.com/prometheus/prometheus v0.315.1 // indirect
	github.com/prometheus/sigv4 v0.5.0 // indirect
	github.com/rogpeppe/go-internal v1.14.1 // indirect
	github.com/rs/cors v1.11.1 // indirect
	github.com/shirou/gopsutil/v4 v4.26.10 // indirect
	github.com/spf13/cobra v1.10.2 // indirect
	github.com/stretchr/objx v0.5.3 // indirect
	github.com/tidwall/gjson v1.10.2 // indirect
	github.com/tidwall/match v1.1.1 // indirect
	github.com/tidwall/pretty v1.2.0 // indirect
	github.com/tidwall/tinylru v1.1.0 // indirect
	github.com/tidwall/wal v1.2.1 // indirect
	github.com/tklauser/go-sysconf v0.4.0 // indirect
	github.com/tklauser/numcpus v0.12.0 // indirect
	github.com/twpayne/go-geom v1.6.1 // indirect
	github.com/valyala/fastjson v1.6.10 // indirect
	github.com/x448/float16 v0.8.4 // indirect
	github.com/yusufpapurcu/wmi v1.2.4 // indirect
	go.opentelemetry.io/auto/sdk v1.2.1 // indirect
	go.opentelemetry.io/collector/client v1.71.0 // indirect
	go.opentelemetry.io/collector/component/componentstatus v0.165.0 // indirect
	go.opentelemetry.io/collector/component/componenttest v0.165.0 // indirect
	go.opentelemetry.io/collector/config/configauth v1.71.0 // indirect
	go.opentelemetry.io/collector/config/configcompression v1.71.0 // indirect
	go.opentelemetry.io/collector/config/confighttp v1.71.0 // indirect
	go.opentelemetry.io/collector/config/configmiddleware v1.71.0 // indirect
	go.opentelemetry.io/collector/config/confignet v1.71.0 // indirect
	go.opentelemetry.io/collector/config/configopaque v1.71.0 // indirect
	go.opentelemetry.io/collector/config/configoptional v1.71.0 // indirect
	go.opentelemetry.io/collector/config/configretry v1.71.0 // indirect
	go.opentelemetry.io/collector/config/configtelemetry v0.165.0 // indirect
	go.opentelemetry.io/collector/config/configtls v1.71.0 // indirect
	go.opentelemetry.io/collector/confmap/xconfmap v0.165.0 // indirect
	go.opentelemetry.io/collector/connector v0.165.0 // indirect
	go.opentelemetry.io/collector/connector/connectortest v0.165.0 // indirect
	go.opentelemetry.io/collector/connector/xconnector v0.165.0 // indirect
	go.opentelemetry.io/collector/consumer/consumererror v0.165.0 // indirect
	go.opentelemetry.io/collector/consumer/consumertest v0.165.0 // indirect
	go.opentelemetry.io/collector/consumer/xconsumer v0.165.0 // indirect
	go.opentelemetry.io/collector/exporter/exporterhelper v0.165.0 // indirect
	go.opentelemetry.io/collector/exporter/exportertest v0.165.0 // indirect
	go.opentelemetry.io/collector/exporter/xexporter v0.165.0 // indirect
	go.opentelemetry.io/collector/extension/extensionauth v1.71.0 // indirect
	go.opentelemetry.io/collector/extension/extensioncapabilities v0.165.0 // indirect
	go.opentelemetry.io/collector/extension/extensionmiddleware v0.165.0 // indirect
	go.opentelemetry.io/collector/extension/extensiontest v0.165.0 // indirect
	go.opentelemetry.io/collector/extension/xextension v0.165.0 // indirect
	go.opentelemetry.io/collector/internal/componentalias v0.165.0 // indirect
	go.opentelemetry.io/collector/internal/fanoutconsumer v0.165.0 // indirect
	go.opentelemetry.io/collector/internal/telemetry v0.165.0 // indirect
	go.opentelemetry.io/collector/pdata/pprofile v0.165.0 // indirect
	go.opentelemetry.io/collector/pdata/testdata v0.165.0 // indirect
	go.opentelemetry.io/collector/pdata/xpdata v0.165.0 // indirect
	go.opentelemetry.io/collector/pipeline v1.71.0 // indirect
	go.opentelemetry.io/collector/pipeline/xpipeline v0.165.0 // indirect
	go.opentelemetry.io/collector/processor v1.71.0 // indirect
	go.opentelemetry.io/collector/processor/processorhelper v0.164.0 // indirect
	go.opentelemetry.io/collector/processor/processortest v0.165.0 // indirect
	go.opentelemetry.io/collector/processor/xprocessor v0.165.0 // indirect
	go.opentelemetry.io/collector/receiver/receiverhelper v0.165.0 // indirect
	go.opentelemetry.io/collector/receiver/receivertest v0.165.0 // indirect
	go.opentelemetry.io/collector/receiver/xreceiver v0.165.0 // indirect
	go.opentelemetry.io/collector/service/hostcapabilities v0.165.0 // indirect
	go.opentelemetry.io/contrib/bridges/otelzap v0.21.0 // indirect
	go.opentelemetry.io/contrib/detectors/aws/ec2/v2 v2.6.0 // indirect
	go.opentelemetry.io/contrib/detectors/aws/ecs v1.47.0 // indirect
	go.opentelemetry.io/contrib/detectors/aws/eks v1.47.0 // indirect
	go.opentelemetry.io/contrib/detectors/azure/azurevm v0.19.0 // indirect
	go.opentelemetry.io/contrib/detectors/gcp v1.47.0 // indirect
	go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.72.0 // indirect
	go.opentelemetry.io/contrib/otelconf v0.27.0 // indirect
	go.opentelemetry.io/contrib/propagators/autoprop v0.72.0 // indirect
	go.opentelemetry.io/contrib/propagators/aws v1.47.0 // indirect
	go.opentelemetry.io/contrib/propagators/b3 v1.47.0 // indirect
	go.opentelemetry.io/contrib/propagators/jaeger v1.47.0 // indirect
	go.opentelemetry.io/contrib/propagators/ot v1.47.0 // indirect
	go.opentelemetry.io/otel v1.47.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploggrpc v0.23.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploghttp v0.23.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc v1.47.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp v1.47.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlptrace v1.47.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc v1.47.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp v1.47.0 // indirect
	go.opentelemetry.io/otel/exporters/prometheus v0.69.0 // indirect
	go.opentelemetry.io/otel/exporters/stdout/stdoutlog v0.23.0 // indirect
	go.opentelemetry.io/otel/exporters/stdout/stdoutmetric v1.47.0 // indirect
	go.opentelemetry.io/otel/exporters/stdout/stdouttrace v1.47.0 // indirect
	go.opentelemetry.io/otel/log v1.47.0 // indirect
	go.opentelemetry.io/otel/metric v1.47.0 // indirect
	go.opentelemetry.io/otel/sdk v1.47.0 // indirect
	go.opentelemetry.io/otel/sdk/log v1.47.0 // indirect
	go.opentelemetry.io/otel/trace v1.47.0 // indirect
	go.opentelemetry.io/proto/otlp v1.11.1 // indirect
	go.uber.org/atomic v1.11.0 // indirect
	go.uber.org/multierr v1.11.0 // indirect
	go.yaml.in/yaml/v2 v2.4.4 // indirect
	go.yaml.in/yaml/v3 v3.0.6 // indirect
	golang.org/x/crypto v0.58.0 // indirect
	golang.org/x/net v0.62.0 // indirect
	golang.org/x/oauth2 v0.37.0 // indirect
	golang.org/x/sync v0.24.0 // indirect
	golang.org/x/term v0.47.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	golang.org/x/time v0.16.0 // indirect
	gonum.org/v1/gonum v0.17.0 // indirect
	google.golang.org/api v0.297.0 // indirect
	google.golang.org/genproto/googleapis/api v0.0.0-20260928230214-8a89bd6388cc // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260928230214-8a89bd6388cc // indirect
	google.golang.org/grpc v1.85.0 // indirect
	google.golang.org/protobuf v1.36.12 // indirect
	gopkg.in/inf.v0 v0.9.1 // indirect
	k8s.io/apimachinery v0.37.1 // indirect
	k8s.io/client-go v0.37.1 // indirect
	k8s.io/klog/v2 v2.140.0 // indirect
	k8s.io/kube-openapi v0.0.0-20260821135717-be32def86098 // indirect
	k8s.io/utils v0.0.0-20260707023825-cf1189d6abe3 // indirect
	sigs.k8s.io/json v0.0.0-20260909141634-11ed52e25bc5 // indirect
	sigs.k8s.io/randfill v1.0.0 // indirect
	sigs.k8s.io/structured-merge-diff/v6 v6.4.2 // indirect
	sigs.k8s.io/yaml v1.6.0 // indirect
)

replace github.com/mattn/go-ieproxy => github.com/mattn/go-ieproxy v0.0.1

replace github.com/cilium/ebpf => github.com/cilium/ebpf v0.11.0

replace github.com/dynatrace/dynatrace-bindplane-otel-collector/pkg/report => ../../pkg/report

// Replace statements to pull in changes from this PR: https://github.com/observIQ/opentelemetry-collector-contrib/pull/4729
// Remove once the above PR is merged, released, and the relevant components are updated to that version.
// The commits being replaced to are built on the OTel v0.165.1 tag.
// https://github.com/observIQ/opentelemetry-collector-contrib/tree/otel-v0.165.1
replace github.com/open-telemetry/opentelemetry-collector-contrib/receiver/windowseventlogreceiver => github.com/observiq/opentelemetry-collector-contrib/receiver/windowseventlogreceiver v0.0.0-20261119153247-0f6e7e87475e

replace github.com/open-telemetry/opentelemetry-collector-contrib/pkg/stanza => github.com/observiq/opentelemetry-collector-contrib/pkg/stanza v0.0.0-20261119153247-0f6e7e87475e
