#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# Moteur de conteneurs : Docker s'il est démarré, sinon Podman. RGAA_ENGINE=docker ou podman pour forcer.
engine="${RGAA_ENGINE:-}"
if [ -z "$engine" ]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        engine=docker
    elif command -v podman >/dev/null 2>&1; then
        engine=podman
    elif command -v docker >/dev/null 2>&1; then
        echo "Docker n'est pas démarré (ou l'utilisateur n'a pas le droit de l'utiliser). Le lancer, puis relancer ce script." >&2
        exit 1
    else
        echo "Ni Docker ni Podman n'est installé :" >&2
        echo "  Docker : https://www.docker.com/products/docker-desktop/" >&2
        echo "  Podman : https://podman.io/docs/installation" >&2
        exit 1
    fi
fi

if ! "$engine" info >/dev/null 2>&1; then
    # Sous macOS et Windows, Podman tourne dans une machine virtuelle qu'il faut démarrer (et créer la première fois).
    if [ "$engine" = podman ] && [ "$(uname -s)" != Linux ]; then
        if ! podman machine inspect >/dev/null 2>&1; then
            echo "Création de la machine virtuelle Podman (une seule fois)..."
            podman machine init
        fi
        echo "Démarrage de la machine virtuelle Podman..."
        podman machine start || true
    fi
    if ! "$engine" info >/dev/null 2>&1; then
        echo "$engine n'est pas démarré (ou l'utilisateur n'a pas le droit de l'utiliser). Le lancer, puis relancer ce script." >&2
        exit 1
    fi
fi

if "$engine" compose version >/dev/null 2>&1; then
    compose=("$engine" compose)
elif command -v "$engine-compose" >/dev/null 2>&1; then
    compose=("$engine-compose")
else
    echo "Il manque l'outil compose : installer « $engine-compose » (ou le plugin « $engine compose »)." >&2
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

"${compose[@]}" up -d

token="$(sed -n 's/^RGAA_API_TOKENS=//p' .env | head -n 1 | cut -d, -f1)"
bind="$(sed -n 's/^RGAA_BIND_ADDRESS=//p' .env | head -n 1)"
echo
echo "========================================"
echo " RGAA Helper est prêt"
echo " Adresse : http://localhost:38080"
if [ -n "$bind" ] && [ "$bind" != 127.0.0.1 ]; then
    # Accessible depuis d'autres machines (par exemple l'ordinateur qui héberge cette VM).
    ip="$( (hostname -I 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || true) | awk '{print $1}')"
    if [ "$bind" != 0.0.0.0 ]; then
        ip="$bind"
    fi
    if [ -n "$ip" ]; then
        echo "           http://$ip:38080 (depuis une autre machine)"
    fi
fi
echo " Jeton   : $token"
echo "========================================"
hosts="$(sed -n 's/^RGAA_ALLOWED_HOSTS=//p' .env | head -n 1)"
if [ -n "$hosts" ] && [ "$hosts" != "*" ]; then
    # .env créé avant la 1.0.2 : la liste limite encore les sites analysables.
    echo " Sites limités à : ${hosts//,/, }"
    echo " Pour autoriser tous les sites, supprimer la ligne RGAA_ALLOWED_HOSTS de $PWD/.env, puis relancer ce script."
fi
echo " Arrêt : ${compose[*]} down"
