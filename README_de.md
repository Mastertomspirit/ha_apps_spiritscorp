[ [Deutsch](README_de.md) | [English](README.md) ]

# SpiritScorp Home Assistant Apps

High-Performance und Production-Grade Apps für deine Home Assistant Infrastruktur. Fokus auf erweiterte Observability, Monitoring und skalierbare Metrik-Verarbeitung.

---

[![Open your Home Assistant instance and show the App Store with a specific repository filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FMastertomspirit%2Fha_apps_spiritscorp)

---

## Verfügbare Apps

| App | Beschreibung | Status |
| :--- | :--- | :---: |
| **[Grafana Mimir](./mimir)** | Hochskalierbarer Long-Term Storage für Prometheus-Metriken inkl. Nginx-Proxy und Multi-Tenancy. | `Stable` |
| <!-- NEW_APP_NAME --> | <!-- Beschreibung der nächsten App --> | `Planned` |

---

## Installation

### Variante 1: Direkt per Button (Empfohlen)
Klicke einfach auf den folgenden Button, um das Repository direkt zu deinem Home Assistant App Store hinzuzufügen:

[![Repository hinzufügen](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FMastertomspirit%2Fha_apps_spiritscorp)

---

### Variante 2: Manuelle Installation
1. Öffne dein **Home Assistant Dashboard**.
2. Navigiere zu **Einstellungen** → **Apps** → **App Store**.
3. Klicke oben rechts auf das Drei-Punkte-Menü (⋮) und wähle **Repositories**.
4. Füge folgende URL hinzu:

```text

https://github.com/Mastertomspirit/ha_apps_spiritscorp

```

5. Klicke auf **Hinzufügen** und lade die Seite neu.
6. Wähle die gewünschte App aus der Liste und klicke auf **Installieren**.

---

## Repository-Struktur

```markdown

.
├── mimir/               # Grafana Mimir App
│   ├── config.yaml      # App-Konfiguration & Schema
│   ├── DOCS_de.md       # Dokumentation (DE)
│   ├── DOCS.md          # Dokumentation (EN)
│   └── rootfs/          # Anwendungsdateien & Skripte
├── README_de.md         # Hauptdokumentation (Deutsch)
└── README.md            # Hauptdokumentation (Englisch)

```
