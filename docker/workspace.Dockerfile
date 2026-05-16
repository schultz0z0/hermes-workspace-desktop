FROM ghcr.io/outsourc-e/hermes-workspace:latest

USER root

COPY docker/install-hermes-tools.sh /usr/local/bin/install-hermes-tools.sh
RUN chmod +x /usr/local/bin/install-hermes-tools.sh && \
    /usr/local/bin/install-hermes-tools.sh

ENV PATH="/opt/hermes-tools-venv/bin:${PATH}"
