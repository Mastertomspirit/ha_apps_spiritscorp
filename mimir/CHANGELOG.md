# Changelog - Grafana Mimir Home Assistant App

All notable changes to this Home Assistant App will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.8.3] - 2026-10-30

### Changed
- Upgraded Grafana Mimir core component from `3.2.1` to `3.2.3`.
- Configured `index_header` lazy loading with an idle timeout (`13h`) to prevent premature cache eviction and eliminate spurious disk-stat warning logs.
- Standardized CI and Lint workflow triggers to consistently run on `push` and `pull_request` for `main` and `dev` branches.

### Fixed
- Fixed missing permission definitions in GitHub Actions CI workflows to resolve CodeQL security scanning alerts.

## [0.8.2] - 2026-09-10

### Added
- Initial release of the Grafana Mimir Home Assistant App.

[0.8.3]: https://github.com/mastertomspirit/ha_apps_spiritscorp/compare/mimir-v0.8.2...mimir-v0.8.3
[0.8.2]: https://github.com/mastertomspirit/ha_apps_spiritscorp/releases/tag/mimir-v0.8.2
