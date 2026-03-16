# Komodor OpenTelemetry Collector

The Komodor agent deploys an [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) as a sidecar container inside each `komodor-daemon` DaemonSet pod. It is the single pipeline responsible for shipping **traces**, **metrics**, and **logs** produced by the internal components of the Komodor operator to the Komodor backend for operational monitoring purposes. It does **not** collect or forward any end-user workload data, application traces, or business metrics from the cluster.

## Architecture overview

```
  ┌──────────────────────────────────────────────────────────────────────────┐
  │  komodor-daemon pod (per node)                                           │
  │                                                                          │
  │  ┌───────────────┐  OTLP/HTTP (traces, metrics)  ┌──────────────────┐   │
  │  │  k8s-watcher  │ ────────────────────────────► │  otel-collector  │   │
  │  └───────────────┘                               │                  │   │
  │                                                  │  :4318  OTLP/HTTP│   │
  │  ┌──────────────────────────────────┐            │  :4317  OTLP/gRPC│   │
  │  │  /var/log/pods  (host mount)     │            │                  │   │
  │  │  • komodor-daemon/*/*/*.log      │ ─ tail ──► │  filelog/komodor │   │
  │  │  • komodor-podmotion/*/*/*.log   │            │                  │   │
  │  └──────────────────────────────────┘            │                  │   │
  │                                                  │                  │   │
  │  ┌──────────────────────────────────┐  health    │                  │   │
  │  │  k8s-watcher  :healthCheck       │ ◄── poll ─ │  httpcheck/local │   │
  │  └──────────────────────────────────┘            │  (every 60s)     │   │
  │                                                  │                  │   │
  └──────────────────────────────────────────────────┼──────────────────┘   │
                                                     │                      │
  ┌──────────────────────────────────┐  health       │                      │
  │  admission-controller  :8443     │ ◄── poll ─────┘  (when AC enabled)   │
  └──────────────────────────────────┘                                      │
                                                                             │
  ┌──────────────────────────────────┐  OTLP/HTTP (traces, metrics)         │
  │  admission-controller            │ ────────────────────────────────────►│
  └──────────────────────────────────┘         (via ClusterIP service :4318)│
                                                                             │
  ┌──────────────────────────────────┐  Prometheus scrape                   │
  │  komodor-podmotion pods          │ ◄───────────────────────────────────►│
  │  (annotation: scrape=true)       │  kubernetes_sd (all nodes)           │
  └──────────────────────────────────┘                                      │
                                                       │                    │
                          ┌────────────────────────────┤                   │
                          │                            │                    │
              ┌───────────▼──────────┐   ┌────────────▼──────┐  ┌─────────▼──────┐
              │  Komodor backend     │   │  Your Prometheus   │  │  Your Prometheus│
              │  (otlphttp/komodor)  │   │  :9090             │  │  :8888          │
              │                      │   │  health-check      │  │  collector self │
              │  • traces            │   │  metrics           │  │  metrics        │
              │  • metrics           │   │  (httpcheck.*)     │  │  (pipeline      │
              │  • logs              │   │                    │  │   throughput,   │
              │  • health metrics    │   │                    │  │   memory, etc.) │
              └──────────────────────┘   └────────────────────┘  └────────────────┘
```

## Configuration

Configuration is sourced in one of two ways depending on the `otelInit` setting:

| Mode | `otelInit.enabled` | Source |
|---|---|---|
| **Remote (recommended)** | `true` | `otel-init` init container fetches config from the Komodor backend at startup; `otel-init-sidecar` polls for updates every `pollingIntervalSeconds` (default: 300 s) and signals the collector to hot-reload |
| **Static (fallback)** | `false` | ConfigMap rendered by Helm at deploy time from the template in this directory |

Enable or disable the feature entirely:

```yaml
capabilities:
  telemetry:
    enabled: true          # master switch for all telemetry
    deployOtelCollector: true  # deploy the collector sidecar
```

---

## Data pipelines

### `traces` — Application traces

| | |
|---|---|
| **Receiver** | `otlp` (HTTP `:4318`) |
| **Processors** | `memory_limiter` → `batch` |
| **Destination** | **Komodor backend** |

Receives OpenTelemetry traces from `k8s-watcher` and the `admission-controller` via OTLP/HTTP and forwards them to Komodor.

---

### `metrics` — Agent & pod-motion metrics

| | |
|---|---|
| **Receivers** | `otlp` (HTTP `:4318`), `prometheus/komodor-podmotion` |
| **Processors** | `memory_limiter` → `attributes/upsert-cluster` → `batch` |
| **Destination** | **Komodor backend** |

Two sources feed this pipeline:

- **OTLP** — internal metrics pushed by `k8s-watcher` and the `admission-controller`.
- **Prometheus scrape (`komodor-podmotion`)** — the collector scrapes any pod in the cluster annotated with `prometheus.io/scrape: "true"` and labelled `app.kubernetes.io/name: komodor-podmotion`. The `komodor.cluster.name` attribute is stamped on every datapoint before forwarding.

---

### `logs` — Agent component logs

| | |
|---|---|
| **Receiver** | `filelog/komodor` |
| **Processors** | `memory_limiter` → `batch` |
| **Destination** | **Komodor backend** |

Tails log files from `/var/log/pods` on the host for:

- All containers of the `komodor-daemon` pod (except the `otel-collector` container itself, to avoid log loops).
- All `komodor-podmotion` pods.

Each log line is enriched with `namespace`, `pod`, `container`, and `komodor.cluster.name` attributes. The collector attempts to parse Kubernetes container-runtime headers and JSON-structured log bodies; unparseable lines are forwarded as-is.

---

### `metrics/local` — Health-check metrics (local Prometheus)

| | |
|---|---|
| **Receivers** | `otlp`, `httpcheck/local` |
| **Processors** | `memory_limiter` → `filter/local` |
| **Destination** | **End-user Prometheus** (`:9090`) |

This pipeline is the **end-user-accessible** one. It exposes a Prometheus endpoint at `:9090` on the collector service, allowing you to scrape agent health metrics into your own monitoring stack.

The `filter/local` processor ensures only the relevant metrics are published:

- `httpcheck.*` metrics (component health checks, see below).
- `komodor.agent.telemetry.agent.task.handler.*` metrics (internal agent task handler instrumentation [= User or system initiated actions such as Describe, Restart, Edit etc..]).
- `komodor.agent.telemetry.live.data.session.watch.sessions` (live data session gauge [In UI: Kubernetes Explorer]).

---

## Health-check metrics

The `httpcheck/local` receiver polls the health endpoints of the agent components every **60 seconds** and emits two metrics per check:

| Metric | Type | Description |
|---|---|---|
| `httpcheck.status` | Gauge | `1` if the HTTP response status was 2xx, `0` otherwise |
| `httpcheck.validation.passed` | Gauge | `1` if the JSON body validation passed (`status == "healthy"`), `0` otherwise |
| `httpcheck.validation.failed` | Gauge | `1` if the JSON body validation failed, `0` otherwise |

Each datapoint carries an `http.url` attribute identifying the exact endpoint and check that was polled.

### Watcher checks (always active)

| Check | Endpoint | What it tests |
|---|---|---|
| `komodor_heartbeat` | `WATCHER_HEALTH_ENDPOINT?check=komodor_heartbeat` | The watcher process is alive and backend communication is healthy |
| `kubernetes_api` | `WATCHER_HEALTH_ENDPOINT?check=kubernetes_api` | The watcher can reach the Kubernetes API server |

### Admission Controller checks (when `capabilities.admissionController.enabled: true`)

These checks are only active when the Admission Controller is deployed. The `ADMISSION_CONTROLLER_ENABLED` environment variable is always present on the collector container (`"true"` / `"false"`); the `filter/local` processor uses it to drop Admission Controller datapoints at runtime when the controller is disabled — this makes the behaviour correct even when the collector configuration is received remotely.

| Check | Endpoint | What it tests |
|---|---|---|
| `komodor_backend` | `ADMISSION_CONTROLLER_HEALTH_ENDPOINT?check=komodor_backend` | The Admission Controller can reach the Komodor backend |
| `kubernetes_api` | `ADMISSION_CONTROLLER_HEALTH_ENDPOINT?check=kubernetes_api` | The Admission Controller can reach the Kubernetes API server |

---

## Exposed ports and what they are for

| Port | Name | Accessible to | Purpose |
|---|---|---|---|
| `4317` | `otlp-grpc` | Internal (pod) | OTLP gRPC receiver (intra-pod use) |
| `4318` | `otlp-http` | Internal (ClusterIP service) | OTLP HTTP receiver — watcher pushes traces and metrics here |
| `8888` | `otel-prom` | End-user (ClusterIP service) | OpenTelemetry Collector's own internal metrics (pipeline throughput, dropped spans, memory limiter stats, etc.) |
| `9090` | `local-prom` | **End-user** (ClusterIP service) | Agent health-check metrics — scrape this for alerting on agent health |
| `13133` | `health-check` | Internal (liveness/readiness probes) | Collector health check extension (`GET /status/health`) |

The ClusterIP service exposes ports `4318`, `8888`, and `9090`. To scrape health or internal metrics, add the service as a Prometheus target using the label selector for the `komodor-daemon` DaemonSet.

---

## Resource configuration

```yaml
components:
  komodorDaemon:
    opentelemetry:
      resources:
        limits:
          cpu: 200m
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 128Mi
```

Memory is managed at the pipeline level by the `memory_limiter` processor (75% limit, 20% spike headroom). The `GOMEMLIMIT` environment variable is automatically derived from the container memory limit to align Go's GC pressure with the Kubernetes limit.

> **Note:** The collector's memory footprint is directly tied to the volume of activity in the cluster. The Komodor agent observes and reacts to Kubernetes events, API calls, and workload changes — the more active and larger the cluster, the higher the throughput through the collector's pipelines. In busy clusters or clusters with many namespaces and frequent deployments, you should expect to increase the memory limit accordingly. If the `memory_limiter` processor starts dropping data, it will be visible in the collector's self-metrics at `:8888` (`otelcol_processor_dropped_metric_points`, `otelcol_processor_dropped_log_records`, `otelcol_processor_dropped_spans`).

---

## What Komodor receives vs. what you control

| Data | Destination | Content |
|---|---|---|
| Traces | Komodor backend | Internal agent operational traces |
| Metrics | Komodor backend | Internal agent operational metrics |
| Logs | Komodor backend | Structured logs from all agent containers and komodor-podmotion pods |
| Health metrics | **Your Prometheus** (`:9090`) | `httpcheck.*` agent health checks as well as select operational metrics we consider critical and actionable |
| Collector internals | **Your Prometheus** (`:8888`) | OTel Collector pipeline throughput, error rates, memory usage |

No raw Kubernetes resource data, secrets, or workload payloads are collected by this component. The collector only processes telemetry signals explicitly emitted by the Komodor operator components themselves.

> **Opting out:** Telemetry sent to the Komodor backend can be disabled via `capabilities.telemetry.enabled: false`. The collector sidecar itself can be removed entirely via `capabilities.telemetry.deployOtelCollector: false`. Be aware that doing so will significantly reduce Komodor's ability to detect, diagnose, and help troubleshoot issues with the agent if they arise.
