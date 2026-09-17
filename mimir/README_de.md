# Home Assistant App: Grafana Mimir

[![GitHub Release](https://img.shields.io/github/v/release/mastertomspirit/ha_apps_spiritscorp?style=plastic&logo=github&label=Release&color=blue)](https://github.com/mastertomspirit/ha_apps_spiritscorp/releases)
[![Grafana Mimir Core](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmastertomspirit%2Fha_apps_spiritscorp%2Fmain%2Fmimir%2Fbuild.yaml&query=%24.args.MIMIR_VERSION&label=Mimir&prefix=v&color=orange&style=plastic&logo=grafana)](https://grafana.com/oss/mimir/)
[![CI Build Status](https://img.shields.io/github/actions/workflow/status/mastertomspirit/ha_apps_spiritscorp/ci.yaml?branch=main&style=plastic&logo=githubactions&label=Build)](https://github.com/mastertomspirit/ha_apps_spiritscorp/actions/workflows/ci.yaml)

[![Architecture](https://img.shields.io/badge/Arch-aarch64%20%7C%20amd64-green.svg?style=plastic)](https://github.com/mastertomspirit/ha_apps_spiritscorp)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-purple.svg?style=plastic)](https://www.gnu.org/licenses/gpl-3.0)
[![Home Assistant Ingress](https://img.shields.io/badge/Ingress-Ready-brightgreen.svg?style=plastic&logo=homeassistant)](https://www.home-assistant.io/)

<br>

[![README - Deutsch](https://img.shields.io/badge/README-Deutsch_🇩🇪-blue?style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/README_de.md)
<-----------------------------------> [![README - English](https://img.shields.io/badge/English_🇬🇧-README-grey?labelColor=red&style=plastic)](https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/README.md)

<br>

**Grafana Mimir** ist eine maßgeschneiderte, hochperformante und horizontal skalierbare Langzeit-Speicher-Engine für Prometheus-Metriken im Home Assistant Ökosystem.

Entwickelt für das **SpiritScorp Home Assistant Apps** Repository: [ha_apps_spiritscorp](https://github.com/mastertomspirit/ha_apps_spiritscorp).

---

## 📖 Worum geht es?

Home Assistant erzeugt kontinuierlich wertvolle Sensor-, Zustands- und Energiedaten. Die integrierte SQLite-/Recorder-Datenbank ist jedoch primär für kurzfristige Verläufe und Automationen ausgelegt. Lange Zeiträume führen schnell zu riesigen Datenbankdateien, verlangsamten Backups und zähen Diagrammen.

**Grafana Mimir** löst dieses Problem grundlegend:
- **Echte Langzeitspeicherung**: Jahre an historischen Daten bei minimalem Speicherbedarf dank TSDB-Blockkompression.
- **PromQL**: Abfragen von Jahresverläufen in Grafana beantwortet Mimir in Millisekunden.
- **Prometheus Remote-Write Ingestion**: Home Assistant stellt seine Metriken über den `/api/prometheus`-Endpunkt bereit, von wo aus ein Collector (wie Grafana Alloy, Prometheus Agent oder vmagent) sie per Scrape ausliest und via HTTP Remote-Write an Mimir überträgt. Passende Add-ons für den Collector-Betrieb findest du im [SpechtLabs Repository](https://github.com/SpechtLabs/homeassistant-addons).
- **Leichtgewichtige Monolith-Architektur**: Betreibt Proxy, Distributor, Ingester, Querier und Compactor ressourcenschonend sowie stabil in einem einzelnen Container – optimiert für Single-Node-Setups auf lokalem Speicher oder Object-Storage (S3 / MinIO).

---

## 🚀 Leistungsmerkmale

- **Integrierte Ingress-Weboberfläche**: Live-Überwachung von Readiness, komplette Config (`/config`), Services (`/services`) und Metriken (`/metrics`) direkt in der Home Assistant Seitenleiste.
- **Schutz vor Kardinalitäts-Explosionen**: Vorkonfigurierte Filter gegen flüchtige Attribut-Labels (wie `last_seen`, `uptime`), damit der Speicher schlank bleibt.
- **Multi-Architektur**: Vorkompilierte Container für 64-Bit ARM (`aarch64` z. B. Raspberry Pi 4/5, Home Assistant Yellow/Green) und x86_64 (`amd64` z. B. Intel NUC, Proxmox VM).
- **Flexible Speicher-Architektur**:
  - **Lokal (Standard)**: Extrem schnelles Dateisystem auf `/data/mimir`.
  - **Cloud / S3**: Object-Storage mit MinIO, Garage, AWS S3 oder Ceph.
- **Optionale Mandantentrennung (Multi-Tenancy)**: Trennung von Smart-Home-Daten, Netzwerkmetriken oder getrennten Standorten via `X-Scope-OrgID`.

---

## 🏗️ Architektur-Überblick

```text

┌─────────────────────────┐      Scrape (HTTP Pull)        ┌─────────────────────────┐
│   Home Assistant Core   │ ──────────────────────────────►│    Collector / Agent    │
│ (prometheus Komponente) │                                │ (Grafana Alloy / etc.)  │
└─────────────────────────┘                                └─────────────────────────┘
                                                                        │
                                                                        │
                                               HTTP Remote-Write (Push) │
                                                                        │
                                                                        │
                                                                        ▼
┌─────────────────────────┐         PromQL Abfrage         ┌─────────────────────────┐
│    Grafana Dashboard    │ ─────────────────────────────► │      Grafana Mimir      │
│  (Datasource Prometheus)│ ◄───────────────────────────── │  (Port 9009 / Ingress)  │
└─────────────────────────┘                                └─────────────────────────┘
                                                                        │
                                                                        │
                                                                        ▼
                                                           ┌─────────────────────────┐
                                                           │ Persistenter TSDB Block │
                                                           │  (/data/mimir oder S3)  │
                                                           └─────────────────────────┘

```

---

## ⚡ Schnellstart

1. **Repository hinzufügen**:

   Für eine manuelle installation füge in Home Assistant unter \
   *Einstellungen &rarr; Apps &rarr; App Store &rarr; Repositories* folgendes Repository hinzu:

   ```text
   https://github.com/mastertomspirit/ha_apps_spiritscorp
   ```

2. **Add-on installieren**: Suche nach **Grafana Mimir Observability** und klicke auf *Installieren*.
3. **Starten & Ingress öffnen**: Starte die App und öffne die Web-Benutzeroberfläche über die Seitenleiste.
4. **Detaillierte Konfiguration**: Alle Optionen, Home Assistant YAML-Snippets und Grafana-Einstellungen findest du in der Dokumentation: \
   👉 **[Detaillierte Dokumentation & Konfiguration (DOCS.md)](DOCS.md)** \
    *(oder klicke oben in Home Assistant auf den Tab* **Dokumentation** *)*

---

## 📄 Lizenz

Dieses Projekt ist unter der **GNU General Public License v3.0 (GPL-3.0)** lizenziert.
Weitere Details siehe [LICENSE](https://www.gnu.org/licenses/gpl-3.0).
