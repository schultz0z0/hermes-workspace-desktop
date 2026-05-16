FROM nousresearch/hermes-agent:latest

USER root

COPY docker/install-hermes-tools.sh /usr/local/bin/install-hermes-tools.sh
RUN chmod +x /usr/local/bin/install-hermes-tools.sh && \
    /usr/local/bin/install-hermes-tools.sh

RUN /opt/hermes/.venv/bin/python3 -m ensurepip --upgrade && \
    /opt/hermes/.venv/bin/python3 -m pip install --upgrade pip && \
    /opt/hermes/.venv/bin/python3 -m pip install "hermes-agent[web,pty]" && \
    /opt/hermes/.venv/bin/python3 -m pip install requests httpx beautifulsoup4 lxml pandas openpyxl pypdf python-docx pillow && \
    /opt/hermes/.venv/bin/python3 -m pip install playwright && \
    /opt/hermes/.venv/bin/python3 -m playwright install chromium && \
    /opt/hermes/.venv/bin/python3 -m playwright install-deps

ENV PATH="/opt/hermes-tools-venv/bin:${PATH}"

COPY docker/hermes-all-in-one.sh /usr/local/bin/hermes-all-in-one.sh
RUN chmod +x /usr/local/bin/hermes-all-in-one.sh
