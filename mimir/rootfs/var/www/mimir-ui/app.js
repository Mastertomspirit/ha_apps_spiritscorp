/**
 * =====================================================================
 * Grafana Mimir - Home Assistant Ingress Application Logic (app.js)
 * =====================================================================
 * Handles dynamic Ingress path resolution, Mimir API proxying,
 * multi-tab view switching, and live metrics inspection.
 */

/**
 * Current window pathname used to determine the Ingress base path.
 * @type {string}
 */
const currentPath = window.location.pathname;

/**
 * Normalised base URL ensuring trailing slash for Home Assistant Ingress routing.
 * Avoids root-relative '/' navigation which escapes the Ingress iframe boundary.
 * @type {string}
 */
const baseIngressUrl = currentPath.endsWith('/') ? currentPath : currentPath + '/';

/**
 * Proxied endpoint prefix routed through Nginx to the internal Mimir engine.
 * @type {string}
 */
const mimirProxyUrl = baseIngressUrl + 'proxy/mimir/';

/**
 * Cached raw Prometheus metrics text payload.
 * @type {string}
 */
let rawMetrics = "";

/**
 * Flag indicating whether the Mimir services iframe has already been loaded.
 * @type {boolean}
 */
let servicesLoaded = false;

/**
 * Flag indicating whether the Mimir ring iframe has already been loaded.
 * @type {boolean}
 */
let configLoaded = false;

/**
 * Switches the currently visible tab in the Ingress UI.
 * Lazily initializes iframe sources when their respective tabs are activated.
 *
 * @param {string} tabId - The DOM element ID of the tab pane to activate (e.g. 'tab-dashboard').
 * @returns {void}
 */
function switchTab(tabId) {
  const allPanes = document.querySelectorAll('.tab-pane');
  const allButtons = document.querySelectorAll('.tab-btn');

  allPanes.forEach(pane => pane.classList.remove('active'));
  allButtons.forEach(button => button.classList.remove('active'));

  const targetPane = document.getElementById(tabId);
  if (targetPane) {
    targetPane.classList.add('active');
  }

  if (window.event && window.event.currentTarget) {
    window.event.currentTarget.classList.add('active');
  }

  // Lazy-load Services iframe on first view
  if (tabId === 'tab-services' && !servicesLoaded) {
    const servicesFrame = document.getElementById('frame-services');
    if (servicesFrame) {
      servicesFrame.src = mimirProxyUrl + 'services';
    }
    servicesLoaded = true;
  }

  // Lazy-load Config iframe on first view
  if (tabId === 'tab-config' && !configLoaded) {
    const configFrame = document.getElementById('frame-config');
    if (configFrame) {
      configFrame.src = mimirProxyUrl + 'config';
    }
    configLoaded = true;
  }

  // Auto-fetch metrics if user navigates to metrics tab and cache is empty
  if (tabId === 'tab-metrics' && !rawMetrics) {
    loadMetrics();
  }
}

/**
 * Forces a fresh reload of a specified iframe element by appending a cache-busting timestamp.
 *
 * @param {string} frameId - The DOM ID of the target iframe element.
 * @param {string} endpointPath - The relative path on Mimir to fetch (e.g. 'services' or 'config').
 * @returns {void}
 */
function reloadFrame(frameId, endpointPath) {
  const targetFrame = document.getElementById(frameId);
  if (targetFrame) {
    targetFrame.src = mimirProxyUrl + endpointPath + '?t=' + Date.now();
  }
}

/**
 * Displays a non-intrusive floating toast notification banner for a brief period.
 *
 * @param {string} message - The notification text message to display.
 * @returns {void}
 */
function showToast(message) {
  const toastBanner = document.getElementById('toast');
  if (!toastBanner) return;

  toastBanner.innerText = message;
  toastBanner.style.display = 'block';

  setTimeout(() => {
    toastBanner.style.display = 'none';
  }, 2200);
}

/**
 * Copies the text content of a designated element into the system clipboard
 * and triggers temporary visual confirmation feedback on the invoking button.
 *
 * @param {string} elementId - The DOM ID of the container element containing the text to copy.
 * @param {HTMLElement|null} triggerButton - The button that initiated the copy action.
 * @returns {void}
 */
function copyText(elementId, triggerButton) {
  const sourceElement = document.getElementById(elementId);
  if (!sourceElement) return;

  const textToCopy = sourceElement.innerText || sourceElement.textContent;
  navigator.clipboard.writeText(textToCopy).then(() => {
    showToast("In die Zwischenablage kopiert!");
    if (triggerButton) {
      const originalLabel = triggerButton.innerText;
      triggerButton.innerText = "✓ Kopiert";
      setTimeout(() => {
        triggerButton.innerText = originalLabel;
      }, 2000);
    }
  }).catch(error => {
    console.error("Clipboard copy failed:", error);
  });
}

/**
 * Performs a health check probe against Mimir's /ready endpoint via the Ingress proxy
 * and updates visual readiness badges and status indicators across the dashboard.
 *
 * @returns {void}
 */
function checkHealth() {
  fetch(mimirProxyUrl + 'ready')
    .then(response => {
      const statusBadge = document.getElementById('status-badge');
      const statusText = document.getElementById('status-text');
      const readinessLabel = document.getElementById('dash-ready-val');

      if (response.ok) {
        if (statusBadge) statusBadge.className = 'status-badge';
        if (statusText) statusText.innerText = 'Mimir Online (Ready)';
        if (readinessLabel) readinessLabel.innerText = 'Online (200)';
      } else {
        if (statusBadge) statusBadge.className = 'status-badge loading';
        if (statusText) statusText.innerText = 'Warte auf Mimir...';
        if (readinessLabel) readinessLabel.innerText = 'Initialisiere...';
      }
    })
    .catch(() => {
      const statusBadge = document.getElementById('status-badge');
      const statusText = document.getElementById('status-text');
      const readinessLabel = document.getElementById('dash-ready-val');

      if (statusBadge) statusBadge.className = 'status-badge error';
      if (statusText) statusText.innerText = 'Verbindung getrennt';
      if (readinessLabel) readinessLabel.innerText = 'Offline';
    });
}

/**
 * Fetches raw Prometheus metrics from Mimir (/metrics) via the Ingress proxy
 * and delegates rendering to the filtering routine.
 *
 * @returns {void}
 */
function loadMetrics() {
  const outputContainer = document.getElementById('metrics-output');
  if (!outputContainer) return;

  outputContainer.innerText = "Lade Metriken von " + mimirProxyUrl + "metrics ...";
  fetch(mimirProxyUrl + 'metrics')
    .then(response => {
      if (!response.ok) throw new Error('HTTP ' + response.status);
      return response.text();
    })
    .then(metricsData => {
      rawMetrics = metricsData;
      filterMetrics();
    })
    .catch(error => {
      outputContainer.innerText = "Fehler beim Laden von /metrics: " + error + "\n\nPrüfe, ob Mimir gestartet ist und Nginx den internen Proxy unter proxy/mimir/ weiterleitet.";
    });
}

/**
 * Filters the cached Prometheus metrics according to the user input query
 * and updates the text display with matched lines.
 *
 * @returns {void}
 */
function filterMetrics() {
  const filterInput = document.getElementById('metric-filter');
  const searchQuery = filterInput ? filterInput.value.toLowerCase() : "";
  const outputContainer = document.getElementById('metrics-output');

  if (!outputContainer || !rawMetrics) return;

  if (!searchQuery) {
    outputContainer.innerText = rawMetrics.slice(0, 50000) + "\n\n... (gekürzt, nutze die Suchleiste oben zum Filtern)";
    return;
  }

  const allLines = rawMetrics.split('\n');
  const matchingLines = allLines.filter(metricLine => metricLine.toLowerCase().includes(searchQuery));
  outputContainer.innerText = matchingLines.slice(0, 50000).join('\n') || "Keine übereinstimmenden Metriken gefunden.";
}

/**
 * Formats byte count into human-readable units (B, KB, MB, GB, TB).
 *
 * @param {number} bytes
 * @returns {string}
 */
function formatBytes(bytes) {
  const abs = Math.abs(Number(bytes) || 0);
  const sign = (Number(bytes) || 0) < 0 ? '-' : '';
  if (abs < 1024) return sign + abs + ' B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  let val = abs / 1024;
  let idx = 0;
  while (val >= 1024 && idx < units.length - 1) {
    val /= 1024;
    idx++;
  }
  return sign + val.toFixed(val >= 100 ? 0 : val >= 10 ? 1 : 2) + ' ' + units[idx];
}

/**
 * Fetches DB disk size and daily history from ./proxy/storage-stats.json
 * and renders the stat cards + bar chart.
 *
 * @returns {void}
 */
function loadStorageStats() {
  fetch(baseIngressUrl + 'proxy/storage-stats.json?t=' + Date.now(), { cache: 'no-store' })
    .then(res => {
      if (!res.ok) throw new Error('HTTP ' + res.status);
      return res.json();
    })
    .then(data => {
      const sizeEl = document.getElementById('dash-db-size');
      const pathEl = document.getElementById('dash-db-path');
      const avgEl = document.getElementById('dash-db-avg');
      const avgDescEl = document.getElementById('dash-db-avg-desc');
      const metaEl = document.getElementById('storage-chart-meta');
      const chartEl = document.getElementById('storage-chart');

      if (sizeEl) sizeEl.innerText = formatBytes(data.current_bytes || 0);
      if (pathEl) pathEl.innerText = 'Pfad: ' + (data.storage_path || '/data/mimir');

      const daysTracked = Number(data.days_tracked || 1);
      const avgTotal = Number(data.daily_avg_bytes || 0);
      const avgGrowth = Number(data.daily_growth_avg_bytes || 0);
      if (avgEl) {
        avgEl.innerText = daysTracked > 1
          ? (avgGrowth >= 0 ? '+' : '') + formatBytes(avgGrowth) + ' / Tag'
          : formatBytes(avgTotal);
      }
      if (avgDescEl) {
        avgDescEl.innerText = 'Ø Bestand: ' + formatBytes(avgTotal) + ' (' + daysTracked + ' Tag' + (daysTracked === 1 ? '' : 'e') + ')';
      }
      if (metaEl) {
        metaEl.innerText = 'Erfasste Tage: ' + daysTracked + ' (max. 90) · Letzte Messung: ' + (data.updated_at || '—');
      }

      if (chartEl) {
        const hist = Array.isArray(data.history) ? data.history.slice(-30) : [];
        if (hist.length === 0) {
          chartEl.innerHTML = '<div class="stat-desc">Noch keine Verlaufsdaten vorhanden.</div>';
          return;
        }
        const maxBytes = Math.max(1, ...hist.map(item => Number(item.bytes) || 0));
        chartEl.innerHTML = hist.map(item => {
          const b = Number(item.bytes) || 0;
          const pct = Math.max(4, Math.round((b / maxBytes) * 100));
          const shortDate = String(item.date || '').slice(5);
          const label = formatBytes(b);
          return '<div class="storage-bar-col" title="' + (item.date || '') + ': ' + label + '">' +
            '<div class="storage-bar-val">' + label + '</div>' +
            '<div class="storage-bar-track"><div class="storage-bar" style="height:' + pct + '%;"></div></div>' +
            '<div class="storage-bar-date">' + shortDate + '</div>' +
          '</div>';
        }).join('');
      }
    })
    .catch(() => {
      const sizeEl = document.getElementById('dash-db-size');
      const metaEl = document.getElementById('storage-chart-meta');
      if (sizeEl && sizeEl.innerText === 'Lade...') sizeEl.innerText = '—';
      if (metaEl) metaEl.innerText = 'Speicherstatistik wird nach dem ersten Messintervall angezeigt.';
    });
}

/**
 * Extracts key TSDB stats directly from Mimir's /metrics endpoint for the Dashboard.
 *
 * @returns {void}
 */
function loadDashboardMimirStats() {
  fetch(mimirProxyUrl + 'metrics', { cache: 'no-store' })
    .then(res => (res.ok ? res.text() : Promise.reject(new Error('HTTP ' + res.status))))
    .then(text => {
      const sumMetric = (name) => {
        const re = new RegExp('^' + name + '(?:\\{[^}]*\\})?\\s+([0-9eE.+\\-]+)', 'gm');
        let total = 0;
        let found = false;
        let m;
        while ((m = re.exec(text)) !== null) {
          const v = Number(m[1]);
          if (!isNaN(v)) {
            total += v;
            found = true;
          }
        }
        return found ? total : null;
      };

      const memSeries = sumMetric('cortex_ingester_memory_series');
      const headSeries = sumMetric('cortex_ingester_tsdb_head_series');
      const activeSeries = memSeries !== null ? memSeries : headSeries;
      const compactorRuns = sumMetric('cortex_compactor_runs_completed_total');

      const seriesEl = document.getElementById('dash-active-series');
      const seriesDescEl = document.getElementById('dash-series-desc');
      if (seriesEl) {
        seriesEl.innerText = activeSeries !== null ? Math.round(activeSeries).toLocaleString('de-DE') : '—';
      }
      if (seriesDescEl && compactorRuns !== null) {
        seriesDescEl.innerText = 'Compactor-Läufe: ' + Math.round(compactorRuns).toLocaleString('de-DE');
      }
    })
    .catch(() => {});
}

// Initial health probe and periodic background check every 10 seconds
document.addEventListener('DOMContentLoaded', () => {
  checkHealth();
  loadStorageStats();
  loadDashboardMimirStats();
  setInterval(checkHealth, 10000);
  setInterval(() => {
    loadStorageStats();
    loadDashboardMimirStats();
  }, 60000);
});

