[![Documentation - Deutsch](https://img.shields.io/badge/Documentation-Deutsch_🇩🇪-red?style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/mimir/DOCS_de.md)
<---------------------------------------------------------> [![Documentation - English](https://img.shields.io/badge/English_🇬🇧-Documentation-grey?labelColor=blue&style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/mimir/DOCS.md)

<br>

# Grafana Mimir – Configuration Guide

This documentation provides the complete reference for all App configuration parameters, setup steps for Home Assistant metric ingestion, and Grafana data source configuration.

---

## ⚙️  App Configuration Options

Configure these parameters directly in Home Assistant under the **Configuration** tab of the App:

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `log_level` | `list` | `warn` | Logging verbosity: `debug`, `info`, `warn`, `error`. |
| `retention_period` | `string` | `180d` | Metric retention duration (e.g. `30d`, `3m`, `1y`). |
| `storage_backend` | `list` | `filesystem` | TSDB storage destination: `filesystem` (local SSD) or `s3` (MinIO/Cloud). |
| `storage_path` | `string` | `/data/mimir` | Persistent local directory for block storage inside the container. |
| `multitenancy_enabled` | `bool` | `false` | Enables tenant isolation via `X-Scope-OrgID` HTTP header. |
| `default_tenant_id` | `string` | `homeassistant` | Default tenant ID applied when multi-tenancy is disabled or omitted. |
| `http_listen_port` | `int` | `9009` | HTTP port for Prometheus remote_write and PromQL query endpoints (Nginx proxies internally to 9008). |
| `max_global_series_per_user`| `int` | `250000` | Maximum active series permitted per tenant (protects against memory exhaustion). |
| `ingestion_rate_mb` | `int` | `25` | Maximum metric ingestion throughput in MB/s. |
| `ingestion_burst_size_mb` | `int` | `50` | Ingestion burst buffer capacity in MB. |
| `ruler_enabled` | `bool` | `false` | Evaluates Prometheus recording rules inside Mimir. |
| `alertmanager_enabled` | `bool` | `false` | Runs the embedded Alertmanager service for alert routing. |
| `s3_endpoint` | `string` | `minio.internal:9000` | S3 API endpoint URL (required when `storage_backend: s3`). |
| `s3_bucket_name` | `string` | `mimir-blocks` | S3 bucket name. |
| `s3_access_key` | `string` | `""` | S3 Access Key ID. |
| `s3_secret_key` | `password` | `""` | S3 Secret Access Key (masked in UI). |
| `s3_insecure` | `bool` | `false` | Set `true` if connecting to plain HTTP (non-TLS) MinIO endpoints. |
| `custom_config` | `bool` | `false` | Enable loading a custom `mimir.yaml` file from the Home Assistant config directory. |
| `custom_config_file` | `string` | `mimir.yaml` | Path to custom YAML configuration file at `/homeassistant/mimir.yaml`. |

---

## 🔌 1. Connecting Home Assistant (`configuration.yaml`)

Add this snippet to your Home Assistant `configuration.yaml` to stream metrics to Mimir:

```yaml
prometheus:
  namespace: homeassistant
  filter:
    include_domains:
      - sensor
      - binary_sensor
      - climate
      - switch
      - light
    exclude_entity_globs:
      - sensor.*_last_seen
      - sensor.*_uptime
      - sensor.*_timestamp
```

Restart Home Assistant after saving. The Prometheus integration will push metrics to:
`http://127.0.0.1:9009/api/v1/push`

---

## 📊 2. Connecting Grafana

To connect any Grafana instance (local HA App or external host like Proxmox):

1. In Grafana, navigate to **Administration** &rarr; **Data sources** &rarr; **Add data source**.
2. Select **Prometheus**.
3. **URL**:
   - Local Grafana on same host: `http://localhost:9009/prometheus`
   - External Grafana (e.g., Proxmox VM): `https://<HOME_ASSISTANT_IP>:9009/prometheus`
4. **HTTP Headers** (only required when `multitenancy_enabled: true`):
   - Header: `X-Scope-OrgID`
   - Value: `homeassistant`
5. **Timeout**: `30s` (recommended for heavy multi-month queries).
6. Click **Save & test**. Grafana will report *"Data source is working"*.

---

## 💾 3. Storage Architecture (Filesystem vs. S3)

### A. Local High-Performance filesystem (Default)
- No extra setup required.
- Blocks and Write-Ahead-Log (WAL) persist in `/data/mimir`.
- Retained across App updates and host restarts.

### B. MinIO / S3 Storage
Set in App Configuration:
```yaml
storage_backend: "s3"
s3_endpoint: "192.168.1.50:9000"
s3_bucket_name: "mimir-blocks"
s3_access_key: "YOUR_KEY"
s3_secret_key: "YOUR_SECRET"
s3_insecure: true # if MinIO is running without TLS
s3_region: de-north-1
```

---

## 🔍 4. Troubleshooting

- **Readiness check fails**: Mimir takes 10–20 seconds to establish internal ring state on initial boot. Monitor the App *Log* tab.
- **Port 9009 unreachable**: Ensure port `9009` is assigned in the App *Configuration &rarr; Network* section.
- **Ingress 502 Bad Gateway**: Wait 15 seconds for startup to complete, then press Ctrl+F5.
