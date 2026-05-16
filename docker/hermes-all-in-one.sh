#!/bin/bash
set -e

(while true; do
    chown -R hermes:hermes /opt/data 2>/dev/null || true
    chown -R hermes:hermes /workspace 2>/dev/null || true
    chmod -R u+rwX,go+rX /opt/data 2>/dev/null || true
    chmod -R u+rwX,go+rX /workspace 2>/dev/null || true
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
            run_as_hermes "source /opt/hermes/.venv/bin/activate && cd /opt/hermes && HERMES_DATA_PATH=${HERMES_DATA_PATH:-/opt/data} hermes dashboard --host ${HERMES_DASHBOARD_HOST:-0.0.0.0} --port ${HERMES_DASHBOARD_PORT:-9119} --no-open --insecure" || true
            sleep 5
        done
    ) &
}

start_dashboard

if [ "$#" -eq 0 ]; then
    set -- gateway run
fi

exec /opt/hermes/docker/entrypoint.sh "$@"
