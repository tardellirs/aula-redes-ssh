#!/usr/bin/env bash
set -euo pipefail
#
# apagar-grupo.sh — apaga a instancia de um grupo (servidor + chave SSH).
# Procura nos DOIS provedores (Hetzner e DigitalOcean) e apaga onde encontrar.
#
# Uso:
#   ./apagar-grupo.sh <nome-do-grupo>

ENV_FILE="${HETZNER_ENV_FILE:-/Users/tardelli/Workplace/hackathon-servers/.env}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEYS_DIR="$SCRIPT_DIR/keys"
SENHAS_FILE="$KEYS_DIR/senhas.csv"

if [[ ( -z "${HETZNER_API_TOKEN:-}" || -z "${DIGITALOCEAN_API_TOKEN:-}" ) && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi
[[ -z "${HETZNER_API_TOKEN:-}" ]] && { echo "Erro: HETZNER_API_TOKEN nao definido"; exit 1; }
[[ $# -lt 1 ]] && { echo "Uso: $0 <nome-do-grupo>"; exit 1; }

SLUG=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
NAME="aula-${SLUG}"
echo "Apagando \"$NAME\" (procurando nos dois provedores)..."

hapi() { curl -s -X "$1" "https://api.hetzner.cloud/v1${2}" -H "Authorization: Bearer $HETZNER_API_TOKEN"; }
doapi() { curl -s -X "$1" "https://api.digitalocean.com/v2${2}" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN"; }

# --- Hetzner ---
SID=$(hapi GET "/servers?name=${NAME}" | python3 -c "import sys,json;s=json.load(sys.stdin).get('servers',[]);print(s[0]['id'] if s else '')" 2>/dev/null)
if [[ -n "$SID" ]]; then
  hapi DELETE "/servers/${SID}" > /dev/null
  echo "  -> Hetzner: servidor apagado (ID $SID)"
  KID=$(hapi GET "/ssh_keys?name=${NAME}" | python3 -c "import sys,json;k=json.load(sys.stdin).get('ssh_keys',[]);print(k[0]['id'] if k else '')" 2>/dev/null)
  [[ -n "$KID" ]] && { hapi DELETE "/ssh_keys/${KID}" > /dev/null; echo "  -> Hetzner: chave SSH removida (ID $KID)"; }
fi

# --- DigitalOcean ---
if [[ -n "${DIGITALOCEAN_API_TOKEN:-}" ]]; then
  DID=$(doapi GET "/droplets?per_page=200" | python3 -c "import sys,json;print(next((d['id'] for d in json.load(sys.stdin).get('droplets',[]) if d['name']=='${NAME}'),''))" 2>/dev/null)
  if [[ -n "$DID" ]]; then
    doapi DELETE "/droplets/${DID}" > /dev/null
    echo "  -> DigitalOcean: droplet apagado (ID $DID)"
    DKID=$(doapi GET "/account/keys" | python3 -c "import sys,json;print(next((k['id'] for k in json.load(sys.stdin).get('ssh_keys',[]) if k['name']=='${NAME}'),''))" 2>/dev/null)
    [[ -n "$DKID" ]] && { doapi DELETE "/account/keys/${DKID}" > /dev/null; echo "  -> DigitalOcean: chave SSH removida (ID $DKID)"; }
  fi
fi

[[ -z "$SID" && -z "${DID:-}" ]] && echo "  -> Nenhum servidor com nome $NAME encontrado"

# --- limpeza local ---
if [[ -f "$KEYS_DIR/aula-${SLUG}" ]]; then
  rm -f "$KEYS_DIR/aula-${SLUG}" "$KEYS_DIR/aula-${SLUG}.pub"
  echo "  -> Chave local removida"
fi
if [[ -f "$SENHAS_FILE" ]]; then
  grep -v "^${SLUG}," "$SENHAS_FILE" > "${SENHAS_FILE}.tmp" 2>/dev/null || true
  mv "${SENHAS_FILE}.tmp" "$SENHAS_FILE"
fi

echo "Pronto."
