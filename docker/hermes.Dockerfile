FROM ghcr.io/hostinger/hvps-hermes-agent:latest

USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y curl git build-essential ca-certificates openssl wget gnupg chromium python3-pip python3-venv

RUN /opt/hermes/.venv/bin/python3 -m ensurepip --upgrade && \
    /opt/hermes/.venv/bin/python3 -m pip install --upgrade pip && \
    /opt/hermes/.venv/bin/python3 -m pip install "hermes-agent[web,pty]" && \
    /opt/hermes/.venv/bin/python3 -m pip install playwright && \
    /opt/hermes/.venv/bin/python3 -m playwright install chromium && \
    /opt/hermes/.venv/bin/python3 -m playwright install-deps
