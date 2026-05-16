#!/bin/bash
set -e

export HERMES_DATA_PATH="${HERMES_DATA_PATH:-/opt/data}"
export HERMES_HOME="${HERMES_HOME:-$HERMES_DATA_PATH}"

fix_permissions() {
    mkdir -p "$HERMES_DATA_PATH" /workspace
    chown -R hermes:hermes /opt/data 2>/dev/null || true
    chown -R hermes:hermes /workspace 2>/dev/null || true
    chmod -R u+rwX,go+rX /opt/data 2>/dev/null || true
    chmod -R u+rwX,go+rX /workspace 2>/dev/null || true
}

fix_permissions

(while true; do
    fix_permissions
    sleep 30
done) &

run_as_hermes() {
    su -s /bin/bash hermes -c "$1"
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

start_dashboard

if [ "$#" -eq 0 ]; then
    set -- gateway run
fi

export HERMES_DATA_PATH
export HERMES_HOME

exec /opt/hermes/docker/entrypoint.sh "$@"
