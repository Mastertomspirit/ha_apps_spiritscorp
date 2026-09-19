<div align="center">  
  <a href="https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/README_de.md"><img src="https://img.shields.io/badge/README-🇩🇪_Deutsch-red?style=plastic" alt="README Deutsch"></a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://github.com/Mastertomspirit/ha_apps_spiritscorp/blob/main/README.md"><img src="https://img.shields.io/badge/English_🇬🇧-README-grey?labelColor=blue&style=plastic" alt="README English"></a>
</div>

# SpiritScorp Home Assistant Apps

High-performance and production-grade apps for your Home Assistant infrastructure. Focused on advanced observability, monitoring, and scalable metrics processing.

---

## Available Apps

| App | Description | Status |
| :--- | :--- | :---: |
| **[Grafana Mimir](./mimir)** | Highly scalable long-term storage for Prometheus metrics including Nginx proxy and multi-tenancy. | `Stable` |
| <!-- NEW_APP_NAME --> | <!-- Description of the next app --> | `Planned` |

---

## Installation

### Option 1: Direct via Button (Recommended)
Simply click the button below to add this repository directly to your Home Assistant App Store:

[![Add Repository](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FMastertomspirit%2Fha_apps_spiritscorp)

---

### Option 2: Manual Installation
1. Open your **Home Assistant Dashboard**.
2. Navigate to **Settings** → **Apps** → **App Store**.
3. Click the three-dots menu (⋮) in the top right corner and select **Repositories**.
4. Add the following URL:

```text

https://github.com/Mastertomspirit/ha_apps_spiritscorp

```

5. Click **Add** and refresh the page.
6. Select the desired app from the list and click **Install**.

---

## Repository Structure

```markdown

.
├── mimir/               # Grafana Mimir App
│   ├── config.yaml      # App configuration & schema
│   ├── DOCS_de.md       # Documentation (DE)
│   ├── DOCS.md          # Documentation (EN)
│   └── rootfs/          # Application files & scripts
├── README_de.md         # Main documentation (German)
└── README.md            # Main documentation (English)

```
