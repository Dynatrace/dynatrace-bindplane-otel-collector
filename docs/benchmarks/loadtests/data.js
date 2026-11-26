window.BENCHMARK_DATA = {
  "lastUpdate": 1795661810740,
  "repoUrl": "https://github.com/Dynatrace/dynatrace-bindplane-otel-collector",
  "entries": {
    "Benchmark": [
      {
        "commit": {
          "author": {
            "name": "Evan Bradley",
            "username": "evan-bradley",
            "email": "11745660+evan-bradley@users.noreply.github.com"
          },
          "committer": {
            "name": "GitHub",
            "username": "web-flow",
            "email": "noreply@github.com"
          },
          "id": "a3c284769eae6c1e2c87413b20d3bff0e005f752",
          "message": "chore(tests): Add load tests (#150)\n\n* feat(tests): Add load tests\n\n* Test workflow on PR\n\n* Revert \"Test workflow on PR\"\n\nThis reverts commit baf1c14e937f6ea6e5a0e665e466b7e717ee2fa7.\n\n* Address PR review\n\n* Add Dependabot rule back",
          "timestamp": "2026-11-23T15:01:39Z",
          "url": "https://github.com/Dynatrace/dynatrace-bindplane-otel-collector/commit/a3c284769eae6c1e2c87413b20d3bff0e005f752"
        },
        "date": 1795488856667,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "cpu_percentage_avg",
            "value": 10.328772040869442,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 10.33120857909586,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 217,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 200,
            "unit": "spans",
            "extra": "Log10kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 7.330327141738083,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 7.330993561210016,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 69,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 207,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 130,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 16,
            "unit": "spans",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 9.665280282084767,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 9.666237476056494,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 73,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 219,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 18.99674243860663,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 18.9984023926788,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 100,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 73,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 218,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 114,
            "unit": "spans",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 39.32031512408173,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 39.324012782039745,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 80,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 76,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 228,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 1037,
            "unit": "spans",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 10.330164424547354,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 10.331145682241681,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 231,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 150,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "Metric10kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 9.998246630817595,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 9.999220314129078,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 222,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 150,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "Metric10kDPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 47.65930022281416,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 47.66462422163056,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 70,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 231,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 130,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 1400,
            "unit": "spans",
            "extra": "Metric100kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 89.31829525855214,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 89.32743685900209,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 105,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 228,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 700,
            "unit": "spans",
            "extra": "Metric100kDPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 3.665006358924303,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 3.6653809377810416,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 10,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 67,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 200,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 1000,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 9.332794089157261,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 19.000199236089188,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 50,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 190,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 376,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 350,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 10000,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 13.164396602504661,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 22.33036745858822,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 150,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 121,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 279,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 250,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 7.399318143953853,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 12.643511928950543,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 230,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 175,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 276,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 550,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 14.663540981383228,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 14.665339301918003,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 81,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 219,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "Trace10kSPS/OTLP-gRPC - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 13.329582122332468,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 13.331082722180149,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 222,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 125,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "Trace10kSPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 71.32179869656945,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 71.32814758679537,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 90,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 78,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 232,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "Trace100kSPS/OTLP-gRPC - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 86.642048888032,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 86.65242063322073,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 110,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 79,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 236,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 200,
            "unit": "spans",
            "extra": "Trace100kSPS/OTLP-HTTP - Dropped Span Count"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "name": "Moritz Wiesinger",
            "username": "mowies",
            "email": "6901203+mowies@users.noreply.github.com"
          },
          "committer": {
            "name": "GitHub",
            "username": "web-flow",
            "email": "noreply@github.com"
          },
          "id": "cacecd1974f3b5479fdb1b362d04586a475f8601",
          "message": "chore(slim): add back updater (#147)\n\n* chore(slim): add back updater\n\n* disable windows wince updater wont work without signed msi installer\n\n* fix(slim): pass the release version to the slim binary build\n\nThe Makefile derives VERSION from plain vX.Y.Z tags only, so slim RC tags\nwere stamped as <previous full tag>-SNAPSHOT-<sha> into the collector and\nupdater. Pass the goreleaser version like the full build does.\n\nAssisted-by: Claude Opus 5.5",
          "timestamp": "2026-11-24T15:03:01Z",
          "url": "https://github.com/Dynatrace/dynatrace-bindplane-otel-collector/commit/cacecd1974f3b5479fdb1b362d04586a475f8601"
        },
        "date": 1795575169716,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "cpu_percentage_avg",
            "value": 14.992972049349525,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 14.99600963181835,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 74,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 218,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 300,
            "unit": "spans",
            "extra": "Log10kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 8.99504940665146,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 8.996905478373092,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 70,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 207,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 130,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 13,
            "unit": "spans",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 13.330862222508493,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 13.332130317442227,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 74,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 220,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 28.993126377249112,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 28.996298429196862,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 100,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 74,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 221,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 101,
            "unit": "spans",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 51.32612339880114,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 51.331126710858285,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 80,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 76,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 226,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 900,
            "unit": "spans",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 12.994732524529098,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 12.996256285418166,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 78,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 232,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 150,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "Metric10kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 12.32923901498276,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 12.330435126209093,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 223,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 150,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "Metric10kDPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 56.6587553857659,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 56.66397333357417,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 70,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 76,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 228,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 130,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 1400,
            "unit": "spans",
            "extra": "Metric100kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 89.31993296152422,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 89.32880084953075,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 105,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 76,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 228,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 700,
            "unit": "spans",
            "extra": "Metric100kDPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 4.332367914243814,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 4.333063228948248,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 10,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 67,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 201,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 1000,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 11.832711667313815,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 25.303613985671024,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 50,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 184,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 370,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 350,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 10000,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 10.832436714492411,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 16.669249439069667,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 150,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 117,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 266,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 250,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 6.132997798659234,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 9.051105893830105,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 230,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 159,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 236,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 550,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 19.66316309737475,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 19.66543399793281,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 225,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 300,
            "unit": "spans",
            "extra": "Trace10kSPS/OTLP-gRPC - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 18.65943351142068,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 18.661023697507368,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 223,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 125,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "Trace10kSPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 78.65535634104624,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 78.66275482031129,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 90,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 78,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 232,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "Trace100kSPS/OTLP-gRPC - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 99.31315326473816,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 99.32366612780122,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 110,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 80,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 238,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "Trace100kSPS/OTLP-HTTP - Dropped Span Count"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "name": "renovate[bot]",
            "username": "renovate[bot]",
            "email": "29139614+renovate[bot]@users.noreply.github.com"
          },
          "committer": {
            "name": "GitHub",
            "username": "web-flow",
            "email": "noreply@github.com"
          },
          "id": "0133d38b354106355ef9133c46e1d879fc1daf81",
          "message": "deps: update dependency sigstore/cosign to v3.1.5 (#160)\n\nCo-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-11-25T14:59:47Z",
          "url": "https://github.com/Dynatrace/dynatrace-bindplane-otel-collector/commit/0133d38b354106355ef9133c46e1d879fc1daf81"
        },
        "date": 1795661807817,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "cpu_percentage_avg",
            "value": 13.995269482287743,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 13.999375282544475,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "Log10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 218,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "Log10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 200,
            "unit": "spans",
            "extra": "Log10kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 10.662867657526172,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 10.664122374139447,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 69,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 206,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 130,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 15,
            "unit": "spans",
            "extra": "LogSyslog/syslog-10kDPS-batch-1 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 13.330209429857268,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 13.331798158999593,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 20,
            "unit": "%",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 73,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 218,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "LogSyslog/syslog-10kDPS-batch-100 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 49.321816459021676,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 49.32709108861025,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 100,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 74,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 221,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 139,
            "unit": "spans",
            "extra": "LogSyslog/syslog-70kDPS-batch-1 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 55.65273413453246,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 55.65849171437913,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 80,
            "unit": "%",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 229,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 1100,
            "unit": "spans",
            "extra": "LogSyslog/syslog-70kDPS-batch-100 - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 13.330227221541168,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 13.33157944407325,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 229,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 150,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "Metric10kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 12.663784178324612,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 12.665251367043904,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Metric10kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 76,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 227,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 150,
            "unit": "MiB",
            "extra": "Metric10kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "Metric10kDPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 54.657192316074344,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 54.66397871128415,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 70,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 231,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 130,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 700,
            "unit": "spans",
            "extra": "Metric100kDPS/OTLP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 94.64639918139237,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 94.65849038179581,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 105,
            "unit": "%",
            "extra": "Metric100kDPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 230,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 120,
            "unit": "MiB",
            "extra": "Metric100kDPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 700,
            "unit": "spans",
            "extra": "Metric100kDPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 4.331735061711084,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 4.332779407705695,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 10,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 68,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 199,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 1000,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_1_Prometheus_Endpoint - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 11.832640528286188,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 26.00038792578785,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 50,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 189,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 385,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 350,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 10000,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_10kDPS_-_1_Prometheus_Endpoint - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 14.665443793524425,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 24.341072536777947,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 150,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 118,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 269,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 250,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 0,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_5_Prometheus_Endpoints - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 5.315737087748021,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 8.130167045799693,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 230,
            "unit": "%",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 217,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 255,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 550,
            "unit": "MiB",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 18446744073709552000,
            "unit": "spans",
            "extra": "PrometheusMetric/Prometheus_1kDPS_-_10_Prometheus_Endpoints - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 5.207765449167435,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 5.2085332969691915,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 69,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 198,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 400,
            "unit": "spans",
            "extra": "Trace10kSPS/OTLP-gRPC - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 18.663803782255634,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 18.666189589971065,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 25,
            "unit": "%",
            "extra": "Trace10kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 75,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 222,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 125,
            "unit": "MiB",
            "extra": "Trace10kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 100,
            "unit": "spans",
            "extra": "Trace10kSPS/OTLP-HTTP - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 76.32175570460173,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 76.3298417519388,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 90,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-gRPC - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 77,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 230,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-gRPC - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 400,
            "unit": "spans",
            "extra": "Trace100kSPS/OTLP-gRPC - Dropped Span Count"
          },
          {
            "name": "cpu_percentage_avg",
            "value": 103.9811872383593,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_max",
            "value": 103.9962196334201,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "cpu_percentage_limit",
            "value": 110,
            "unit": "%",
            "extra": "Trace100kSPS/OTLP-HTTP - Cpu Percentage"
          },
          {
            "name": "ram_mib_avg",
            "value": 83,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_max",
            "value": 241,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "ram_mib_limit",
            "value": 140,
            "unit": "MiB",
            "extra": "Trace100kSPS/OTLP-HTTP - RAM (MiB)"
          },
          {
            "name": "dropped_span_count",
            "value": 200,
            "unit": "spans",
            "extra": "Trace100kSPS/OTLP-HTTP - Dropped Span Count"
          }
        ]
      }
    ]
  }
}