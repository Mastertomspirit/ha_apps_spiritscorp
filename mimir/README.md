# Home Assistant App: Grafana Mimir

[![GitHub Release](https://img.shields.io/github/v/release/mastertomspirit/ha_apps_spiritscorp?style=plastic&logo=github&label=Release&color=blue)](https://github.com/mastertomspirit/ha_apps_spiritscorp/releases)
[![Grafana Mimir Core](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmastertomspirit%2Fha_apps_spiritscorp%2Fmain%2Fmimir%2Fbuild.yaml&query=%24.args.MIMIR_VERSION&label=Mimir&prefix=v&color=orange&style=plastic&logo=grafana)](https://grafana.com/oss/mimir/)
[![CI Build Status](https://img.shields.io/github/actions/workflow/status/mastertomspirit/ha_apps_spiritscorp/ci.yaml?branch=main&style=plastic&logo=githubactions&label=Build)](https://github.com/mastertomspirit/ha_apps_spiritscorp/actions/workflows/ci.yaml)

[![Architecture](https://img.shields.io/badge/Arch-aarch64%20%7C%20amd64-green.svg?style=plastic)](https://github.com/mastertomspirit/ha_apps_spiritscorp)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-purple.svg?style=plastic)](https://www.gnu.org/licenses/gpl-3.0)
[![Home Assistant Ingress](https://img.shields.io/badge/Ingress-Ready-brightgreen.svg?style=plastic&logo=homeassistant)](https://www.home-assistant.io/)

<br>

[![README - Deutsch](https://img.shields.io/badge/README-Deutsch_🇩🇪-red?style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/README_de.md)
<-----------------------------------> [![README - English](https://img.shields.io/badge/English_🇬🇧-README-grey?labelColor=blue&style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/README.md)


**Grafana Mimir** is a purpose-built, high-performance, and horizontally scalable long-term Prometheus time-series metric storage engine designed for the Home Assistant ecosystem.

Part of the **SpiritScorp Home Assistant Apps** repository: [ha_apps_spiritscorp](https://github.com/mastertomspirit/ha_apps_spiritscorp).

---

## 📖 What is this App?

Home Assistant continuously captures valuable telemetry: temperature, energy consumption, device state changes, and network activity. The standard internal SQLite/Recorder database is tailored for short-term automations and state recovery, not multi-year analytical queries.

**Grafana Mimir** transforms your observability:
- **True Long-Term Retention**: Keep years of metrics without slowing down Home Assistant or database backups.
- **PromQL Queries**: Run instant aggregations, rates, and multi-year time-series comparisons in Grafana.
- **Prometheus Remote-Write Ingestion**: Home Assistant exposes its metrics via the `/api/prometheus` endpoint, which an intermediate collector (such as Grafana Alloy, Prometheus Agent, or vmagent) scrapes and forwards to Mimir via HTTP Remote-Write push. Suitable collector add-ons can be found in the [SpechtLabs Repository](https://github.com/SpechtLabs/homeassistant-addons).
- **Lightweight Monolithic Architecture**: Runs proxy, distributor, ingester, querier, and compactor resource-efficiently and stably inside a single container – optimized for single-node setups on local or object storage (S3 / MinIO).

---

## 🚀 Key Features

- **Embedded Ingress Control Center**: Real-time health, readiness checks, full config (`/config`), active services (`/services`), and raw metrics (`/metrics`) available directly from your Home Assistant sidebar.
- **Cardinality Explosion Protection**: Curated filter rules to drop noisy attributes (`last_seen`, `uptime`, timestamps).
- **Multi-Architecture**: Native pre-built images for 64-bit ARM (`aarch64`) and x86_64 (`amd64`).
- **Flexible Storage**:
  - **Local Filesystem (Default)**: High-performance block storage under `/data/mimir`.
  - **Object Storage (S3 / MinIO)**: Seamless long-term archiving to any S3-compatible backend.
- **Optional Multi-Tenancy**: Isolate different environments, locations, or sensor groups using the standard `X-Scope-OrgID` header.

---

## 🏗️ Architecture Overview

```text

┌─────────────────────────┐                                ┌─────────────────────────┐
│   Home Assistant Core   │ ────── Scrape (HTTP Pull) ────►│    Collector / Agent    │
│  (prometheus component) │                                │ (Grafana Alloy / etc.)  │
└─────────────────────────┘                                └─────────────────────────┘
                                                                        │
                                               HTTP Remote-Write (Push) │
                                                                        ▼
┌─────────────────────────┐           PromQL Query         ┌─────────────────────────┐
│    Grafana Dashboard    │ ─────────────────────────────► │      Grafana Mimir      │
│  (Datasource Prometheus)│ ◄───────────────────────────── │  (Port 9009 / Ingress)  │
└─────────────────────────┘                                └─────────────────────────┘
                                                                        │
                                                                        ▼
                                                           ┌─────────────────────────┐
                                                           │ Persistent TSDB Block   │
                                                           │  (/data/mimir or S3)    │
                                                           └─────────────────────────┘

```

---

## ⚡ Quickstart

1. **Add Repository**:

   To install it manually In Home Assistant, navigate to \
   *Settings &rarr; Apps &rarr; App Store &rarr; Repositories* and add:

   ```text
   https://github.com/mastertomspirit/ha_apps_spiritscorp
   ```

2. **Install Add-on**: Search for **Grafana Mimir Observability** and click *Install*.
3. **Start & Open Ingress**: Start the app and open the Ingress Web UI from the sidebar.
4. **Configuration Reference**: Complete options table, Home Assistant configuration snippets, and Grafana connection guides are in: \
   👉 **[Detailed Documentation & Configuration Guide (DOCS.md)](DOCS.md)** \
    *(or check the* **Documentation** *tab above in Home Assistant)*

---

## 📄 License

Licensed under the **GNU General Public License v3.0 (GPL-3.0)**.
See [LICENSE](https://www.gnu.org/licenses/gpl-3.0) for details.
