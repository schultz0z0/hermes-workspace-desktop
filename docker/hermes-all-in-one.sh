#!/bin/bash
set -e

(while true; do
    chown -R hermes:hermes /opt/data 2>/dev/null || true
    sleep 30
done) &

run_as_hermes() {
    su -s /bin/bash hermes -c "$1"
}

start_gateway() {
    local name="$1"
    local profile="$2"
    local port="$3"
    local key="$4"

    if [ -z "$port" ] || [ -z "$key" ]; then
        echo "[$name] Missing API_SERVER_PORT or API_SERVER_KEY; gateway skipped."
        return 0
    fi

    (
        while true; do
            echo "[$name] Starting Hermes gateway on port $port..."

            if [ -z "$profile" ]; then
                run_as_hermes "source /opt/hermes/.venv/bin/activate && cd /opt/hermes && API_SERVER_ENABLED=true API_SERVER_HOST=0.0.0.0 API_SERVER_PORT=$port API_SERVER_KEY=$key API_SERVER_CORS_ORIGINS=${HERMES_API_CORS_ORIGINS:-} GATEWAY_ALLOW_ALL_USERS=${GATEWAY_ALLOW_ALL_USERS:-true} HERMES_DATA_PATH=${HERMES_DATA_PATH:-/opt/data} hermes gateway" || true
            else
                run_as_hermes "source /opt/hermes/.venv/bin/activate && cd /opt/hermes && API_SERVER_ENABLED=true API_SERVER_HOST=0.0.0.0 API_SERVER_PORT=$port API_SERVER_KEY=$key API_SERVER_CORS_ORIGINS=${HERMES_API_CORS_ORIGINS:-} GATEWAY_ALLOW_ALL_USERS=${GATEWAY_ALLOW_ALL_USERS:-true} HERMES_DATA_PATH=${HERMES_DATA_PATH:-/opt/data} hermes -p $profile gateway" || true
            fi

            echo "[$name] Gateway exited; restarting in 5 seconds."
            sleep 5
        done
    ) &
}

start_dashboard() {
    if [ "${HERMES_DASHBOARD_ENABLED:-false}" != "true" ]; then
        echo "[dashboard] Disabled."
        return 0
    fi

    if [ -z "${HERMES_DASHBOARD_PORT:-}" ]; then
        echo "[dashboard] Missing HERMES_DASHBOARD_PORT; dashboard skipped."
        return 0
    fi

    (
        while true; do
            echo "[dashboard] Starting Hermes dashboard on port ${HERMES_DASHBOARD_PORT}..."
            run_as_hermes "source /opt/hermes/.venv/bin/activate && cd /opt/hermes && DASHBOARD_HOST=0.0.0.0 DASHBOARD_PORT=${HERMES_DASHBOARD_PORT} hermes dashboard" || true
            echo "[dashboard] Dashboard exited; restarting in 5 seconds."
            sleep 5
        done
    ) &
}

start_dashboard
start_gateway "core" "" "$HERMES_API_PORT_CORE" "$HERMES_API_KEY_CORE"
start_gateway "ens" "ens" "$HERMES_API_PORT_ENS" "$HERMES_API_KEY_ENS"
start_gateway "clementino" "imobiliaria-clementino" "$HERMES_API_PORT_CLEMENTINO" "$HERMES_API_KEY_CLEMENTINO"

exec /opt/hermes/docker/entrypoint.sh "$@"
