#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker n'est pas installé : https://www.docker.com/products/docker-desktop/" >&2
    exit 1
fi
if ! docker info >/dev/null 2>&1; then
    echo "Docker n'est pas démarré. Le lancer, puis relancer ce script." >&2
    exit 1
fi

if [ ! -f .env ]; then
    if command -v openssl >/dev/null 2>&1; then
        token="$(openssl rand -hex 32)"
    else
        token="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
    fi
    umask 077
    awk -v t="$token" '/^RGAA_API_TOKENS=/ { print "RGAA_API_TOKENS=" t; next } { print }' .env.example > .env
fi

docker compose up -d

token="$(sed -n 's/^RGAA_API_TOKENS=//p' .env | head -n 1 | cut -d, -f1)"
echo
echo "========================================"
echo " RGAA Helper est prêt"
echo " Adresse : http://localhost:38080"
echo " Jeton   : $token"
echo "========================================"
echo " Arrêt : docker compose down"

