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
    chown -R hermes:hermes /opt/data 2>/dev/null || true
    chown -R hermes:hermes /workspace 2>/dev/null || true
    chown hermes:hermes /home/hermes 2>/dev/null || true
    chown -h hermes:hermes /home/hermes/.hermes 2>/dev/null || true
    chmod -R u+rwX,go+rX /opt/data 2>/dev/null || true
    chmod -R u+rwX,go+rX /workspace 2>/dev/null || true
    chmod 666 "$HERMES_DATA_PATH/gateway.lock" 2>/dev/null || true

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

fix_permissions

(while true; do
    fix_permissions
    sleep 5
done) &

run_as_hermes() {
    su -s /bin/bash hermes -c "$1"
}

init_kanban() {
    run_as_hermes "source /opt/hermes/.venv/bin/activate && cd /workspace && HERMES_DATA_PATH=$HERMES_DATA_PATH HERMES_HOME=$HERMES_HOME hermes kanban init" || true
    fix_permissions
}

start_dashboard() {
    if [ "${HERMES_DASHBOARD:-0}" != "1" ]; then
        return 0
    fi

    (
        while true; do
            run_as_hermes "source /opt/hermes/.venv/bin/activate && cd /opt/hermes && HERMES_DATA_PATH=$HERMES_DATA_PATH HERMES_HOME=$HERMES_HOME hermes dashboard --host ${HERMES_DASHBOARD_HOST:-0.0.0.0} --port ${HERMES_DASHBOARD_PORT:-9119} --no-open --insecure" || true
            sleep 5
        done
    ) &
}

init_kanban
start_dashboard

if [ "$#" -eq 0 ]; then
    set -- gateway run
fi

export HERMES_DATA_PATH
export HERMES_HOME

exec /opt/hermes/docker/entrypoint.sh "$@"
