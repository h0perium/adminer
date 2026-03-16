#!/usr/bin/env bash
set -euo pipefail

WEBROOT="/var/www/html"
PLUGINS_ENABLED_DIR="${WEBROOT}/plugins-enabled"

log() { echo "[entrypoint] $*"; }

mkdir -p "${PLUGINS_ENABLED_DIR}"
find "${PLUGINS_ENABLED_DIR}" -maxdepth 1 -type f -name 'zz-env-*.php' -delete || true

to_class_name() {
  local name="$1"
  local out="Adminer"
  IFS='-' read -ra parts <<< "$name"
  for p in "${parts[@]}"; do out+="${p^}"; done
  echo "$out"
}

if [[ -n "${ADMINER_PLUGINS:-}" ]]; then
  log "Generating plugin loaders for: ${ADMINER_PLUGINS}"
  for plugin in ${ADMINER_PLUGINS}; do
    plugin_file="${WEBROOT}/plugins/${plugin}.php"
    loader_file="${PLUGINS_ENABLED_DIR}/zz-env-${plugin}.php"
    class_name="$(to_class_name "${plugin}")"

    if [[ -f "${plugin_file}" ]]; then
      cat > "${loader_file}" <<PHP
<?php
require_once __DIR__ . '/../plugins/${plugin}.php';
return class_exists('${class_name}') ? new ${class_name}() : null;
PHP
    else
      log "WARNING: plugin file not found: ${plugin_file}"
    fi
  done
fi

rm -f "${WEBROOT}/adminer.css" || true
if [[ -n "${ADMINER_DESIGN:-}" ]]; then
  if [[ -f "${WEBROOT}/designs/${ADMINER_DESIGN}/adminer.css" ]]; then
    cp "${WEBROOT}/designs/${ADMINER_DESIGN}/adminer.css" "${WEBROOT}/adminer.css"
    log "Applied design: ${ADMINER_DESIGN}"
  else
    log "WARNING: design not found: ${ADMINER_DESIGN}"
  fi
fi

exec "$@"
