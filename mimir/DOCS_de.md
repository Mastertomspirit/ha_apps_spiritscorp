[![Documentation - Deutsch](https://img.shields.io/badge/Documentation-Deutsch_🇩🇪-blue?style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/mimir/DOCS_de.md)
<---------------------------------------------------------> [![Documentation - English](https://img.shields.io/badge/English_🇬🇧-Documentation-grey?labelColor=red&style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/mimir/DOCS.md)

<br>

# Grafana Mimir – Konfigurationsanleitung

Diese Dokumentation beschreibt die vollständige Konfiguration der App, alle verfügbaren Optionen sowie die Anbindung von Home Assistant und externen Grafana-Instanzen.

---

## ⚙️ Add-on Konfigurationsoptionen

Die folgenden Einstellungen können direkt im Home Assistant App Reiter **Konfiguration** angepasst werden:

| Option | Typ | Standard | Beschreibung |
| :--- | :--- | :--- | :--- |
| `log_level` | `list` | `warn` | Detaillierungsgrad der Logs: `debug`, `info`, `warn`, `error`. |
| `retention_period` | `string` | `180d` | Aufbewahrungsdauer der Metriken im Speicher (z. B. `30d`, `3m`, `1y`). |
| `storage_backend` | `list` | `filesystem` | Speicherziel für TSDB-Blöcke: `filesystem` (lokal) oder `s3` (MinIO/Cloud). |
| `storage_path` | `string` | `/data/mimir` | Lokaler Datenpfad im Container (liegt auf persistentem App-Speicher). |
| `multitenancy_enabled` | `bool` | `false` | Aktiviert die Mandantentrennung via `X-Scope-OrgID` HTTP-Header. |
| `default_tenant_id` | `string` | `homeassistant` | Standard-Mandanten-ID bei deaktivierter oder impliziter Mandantentrennung. |
| `http_listen_port` | `int` | `9009` | HTTP-Port für Prometheus Remote-Write und PromQL-Abfragen (Nginx Proxy leitet intern an 9008 weiter). |
| `max_global_series_per_user`| `int` | `250000` | Maximal aktive Zeitreihen pro Mandant (Schutz vor Speicherüberlauf). |
| `ingestion_rate_mb` | `int` | `25` | Maximale Ingestion-Rate in Megabyte pro Sekunde. |
| `ingestion_burst_size_mb` | `int` | `50` | Puffer für kurzzeitige Ingestion-Spitzen. |
| `ruler_enabled` | `bool` | `false` | Ermöglicht die Auswertung von Mimir-eigenen Recording-Regeln. |
| `alertmanager_enabled` | `bool` | `false` | Startet den integrierten Alertmanager für Push-Benachrichtigungen. |
| `s3_endpoint` | `string` | `minio.internal:9000` | S3 API-Endpunkt (nur relevant bei `storage_backend: s3`). |
| `s3_bucket_name` | `string` | `mimir-blocks` | Name des S3-Buckets. |
| `s3_access_key` | `string` | `""` | S3 Access Key. |
| `s3_secret_key` | `password` | `""` | S3 Secret Key (wird in der UI maskiert). |
| `s3_insecure` | `bool` | `false` | `true` für unverschlüsselte HTTP-Verbindung zu internem MinIO. |
| `custom_config` | `bool` | `false` | Eigene `mimir.yaml` aus dem Home Assistant Konfigurationsordner laden. |
| `custom_config_file` | `string` | `mimir.yaml` | Pfad zur benutzerdefinierten YAML-Konfiguration unter `/homeassistant/mimir.yaml`. |

---

## 🔌 1. Home Assistant anbinden (`configuration.yaml`)

Füge der Datei `configuration.yaml` in Home Assistant folgenden Block hinzu, um Metriken direkt an Mimir zu übertragen:

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

Nach dem Speichern muss Home Assistant neu gestartet werden. Die App empfängt anschließend die Metriken unter:
`http://127.0.0.1:9009/api/v1/push`

---

## 📊 2. Grafana Datenquelle konfigurieren

Um Mimir in Grafana (z. B. auf Proxmox oder als HA App) einzubinden:

1. Navigiere in Grafana zu **Administration** &rarr; **Data sources** &rarr; **Add data source**.
2. Wähle **Prometheus**.
3. **URL**:
   - Lokales Grafana im selben HA: `http://localhost:9009/prometheus`
   - Externes Grafana (z. B. Proxmox): `https://<HOME_ASSISTANT_IP>:9009/prometheus`
4. **HTTP Headers** (nur wenn `multitenancy_enabled: true` aktiv ist):
   - Header: `X-Scope-OrgID`
   - Value: `homeassistant`
5. **Timeout**: `30s` (empfohlen für umfangreiche Langzeit-Abfragen).
6. Klicke auf **Save & test**. Grafana sollte mit *"Data source is working"* antworten.

---

## 💾 3. Speicher-Konfiguration (Filesystem vs. S3)

### A. Lokaler Speicher (Standard)
- Keine weiteren Einstellungen notwendig.
- Mimir speichert WAL und komprimierte Blöcke unter `/data/mimir`.
- Dieser Pfad liegt außerhalb des Docker-Containers im persistenten Speicher von Home Assistant und übersteht Neustarts und Updates unbeschadet.

### B. MinIO / S3 Object Storage
Setze im Konfigurator:
```yaml
storage_backend: "s3"
s3_endpoint: "192.168.1.50:9000"
s3_bucket_name: "mimir-blocks"
s3_access_key: "DEIN_KEY"
s3_secret_key: "DEIN_SECRET"
s3_insecure: true # falls MinIO ohne TLS läuft
s3_region: de-north-1
```

---

## 🔍 4. Fehlerbehebung (Troubleshooting)

- **Ready-Check schlägt fehl**: Mimir benötigt beim Erststart ca. 10–20 Sekunden für die Ring-Initialisierung. Prüfe den Reiter *Logs* in der App.
- **Port 9009 nicht erreichbar**: Stelle sicher, dass in der App unter *Konfiguration &rarr; Netzwerk* der Port `9009` freigegeben ist.
- **Ingress zeigt 502 Bad Gateway**: Mimir startet noch. Aktualisiere nach wenigen Sekunden mit Strg+F5.
