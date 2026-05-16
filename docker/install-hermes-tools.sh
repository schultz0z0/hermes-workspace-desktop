#!/bin/sh
set -eu

APT_REQUIRED_PACKAGES="
  ca-certificates
  curl
  wget
  git
  build-essential
  openssl
  gnupg
  jq
  ripgrep
  fd-find
  unzip
  zip
  tar
  less
  nano
  vim-tiny
  openssh-client
  iputils-ping
  dnsutils
  netcat-openbsd
  procps
  htop
  tini
  python3
  python3-pip
  python3-venv
"

APT_OPTIONAL_PACKAGES="
  chromium
  fonts-liberation
  fonts-noto
  fonts-noto-color-emoji
  libnss3
  libatk-bridge2.0-0
  libgtk-3-0
  libxss1
  libasound2
  libasound2t64
  poppler-utils
  tesseract-ocr
  tesseract-ocr-por
  pandoc
  libreoffice
"

APK_REQUIRED_PACKAGES="
  ca-certificates
  curl
  wget
  git
  build-base
  openssl
  gnupg
  jq
  ripgrep
  fd
  unzip
  zip
  tar
  less
  nano
  vim
  openssh-client
  iputils
  bind-tools
  netcat-openbsd
  procps
  htop
  tini
  python3
  py3-pip
  py3-virtualenv
"

APK_OPTIONAL_PACKAGES="
  chromium
  font-liberation
  font-noto
  font-noto-emoji
  nss
  gtk+3.0
  alsa-lib
  poppler-utils
  tesseract-ocr
  tesseract-ocr-data-por
  pandoc
  libreoffice
"

if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $APT_REQUIRED_PACKAGES
  for package in $APT_OPTIONAL_PACKAGES; do
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$package" || \
      echo "Skipping unavailable optional apt package: $package" >&2
  done
  rm -rf /var/lib/apt/lists/*
elif command -v apk >/dev/null 2>&1; then
  apk add --no-cache $APK_REQUIRED_PACKAGES
  for package in $APK_OPTIONAL_PACKAGES; do
    apk add --no-cache "$package" || \
      echo "Skipping unavailable optional apk package: $package" >&2
  done
else
  echo "Unsupported base image: expected apt-get or apk" >&2
  exit 1
fi

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  ln -s "$(command -v fdfind)" /usr/local/bin/fd
fi

if command -v python3 >/dev/null 2>&1; then
  python3 -m venv /opt/hermes-tools-venv
  /opt/hermes-tools-venv/bin/python -m pip install --upgrade pip
  /opt/hermes-tools-venv/bin/python -m pip install \
    requests \
    httpx \
    beautifulsoup4 \
    lxml \
    pandas \
    openpyxl \
    pypdf \
    python-docx \
    pillow
fi
