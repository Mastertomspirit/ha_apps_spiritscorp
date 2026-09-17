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

// Initial health probe and periodic background check every 10 seconds
document.addEventListener('DOMContentLoaded', () => {
  checkHealth();
  setInterval(checkHealth, 10000);
});

