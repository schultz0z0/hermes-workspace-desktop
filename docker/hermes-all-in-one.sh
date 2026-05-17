#!/bin/bash
set -e

export HERMES_DATA_PATH="${HERMES_DATA_PATH:-/opt/data}"
export HERMES_HOME="${HERMES_HOME:-$HERMES_DATA_PATH}"

fix_permissions() {
    mkdir -p "$HERMES_DATA_PATH" /workspace /home/hermes
    if [ ! -L /home/hermes/.hermes ]; then
        rm -rf /home/hermes/.hermes 2>/dev/null || true
        ln -s "$HERMES_DATA_PATH" /home/hermes/.hermes 2>/dev/null || true
    fi
    touch "$HERMES_DATA_PATH/gateway.lock" 2>/dev/null || true
    rm -f "$HERMES_DATA_PATH/.managed" 2>/dev/null || true
    chown -R hermes:hermes /opt/hermes 2>/dev/null || true
    chown -R hermes:hermes /opt/data 2>/dev/null || true
    chown -R hermes:hermes /workspace 2>/dev/null || true
    chown hermes:hermes /home/hermes 2>/dev/null || true
    chown -h hermes:hermes /home/hermes/.hermes 2>/dev/null || true
    chmod -R u+rwX,g+rwX /opt/hermes 2>/dev/null || true
    chmod -R a+rwX /opt/data 2>/dev/null || true
    chmod -R a+rwX /workspace 2>/dev/null || true
    chmod 666 "$HERMES_DATA_PATH/gateway.lock" 2>/dev/null || true
    find "$HERMES_DATA_PATH" -maxdepth 2 -type f \( -name "*.db" -o -name "*.db-wal" -o -name "*.db-shm" -o -name "*.lock" \) -exec chmod 666 {} \; 2>/dev/null || true
    find "$HERMES_DATA_PATH" -maxdepth 2 -type d -exec chmod 777 {} \; 2>/dev/null || true

    # Kanban uses SQLite WAL; DB file and containing dirs must remain writable.
    mkdir -p "$HERMES_DATA_PATH/kanban/boards" 2>/dev/null || true
    chmod 775 "$HERMES_DATA_PATH" "$HERMES_DATA_PATH/kanban" "$HERMES_DATA_PATH/kanban/boards" 2>/dev/null || true
    chown -R hermes:hermes "$HERMES_DATA_PATH/kanban" 2>/dev/null || true

    chmod 666 "$HERMES_DATA_PATH/kanban.db" 2>/dev/null || true
    chmod 666 "$HERMES_DATA_PATH/kanban.db-wal" 2>/dev/null || true
    chmod 666 "$HERMES_DATA_PATH/kanban.db-shm" 2>/dev/null || true

    find "$HERMES_DATA_PATH/kanban/boards" -type f -name "kanban.db*" -exec chmod 666 {} \; 2>/dev/null || true
    find "$HERMES_DATA_PATH/kanban/boards" -type d -exec chmod 775 {} \; 2>/dev/null || true
}

run_as_hermes() {
    su -s /bin/bash hermes -c "$1"
}

configure_kanban() {
    run_as_hermes "HERMES_DATA_PATH=$HERMES_DATA_PATH HERMES_HOME=$HERMES_HOME /opt/hermes/.venv/bin/python3 - <<'PY'
from pathlib import Path

import yaml

config_path = Path('/opt/data/config.yaml')
if not config_path.exists():
    raise SystemExit(0)

data = yaml.safe_load(config_path.read_text()) or {}
kanban = data.setdefault('kanban', {})
if kanban.get('dispatch_in_gateway') is not False:
    kanban['dispatch_in_gateway'] = False
    config_path.write_text(yaml.safe_dump(data, sort_keys=False))
PY" || true
    fix_permissions
}

init_kanban() {
    run_as_hermes "source /opt/hermes/.venv/bin/activate && cd /workspace && HERMES_DATA_PATH=$HERMES_DATA_PATH HERMES_HOME=$HERMES_HOME hermes kanban init" || true
    fix_permissions
}

post_boot_maintenance() {
    (
        sleep 10
        fix_permissions
        configure_kanban
        init_kanban
        while true; do
            fix_permissions
            sleep 10
        done
    ) &
}

fix_permissions
post_boot_maintenance

if [ "$#" -eq 0 ]; then
    set -- gateway run
fi

export HERMES_DATA_PATH
export HERMES_HOME

exec /opt/hermes/docker/entrypoint.sh "$@"
