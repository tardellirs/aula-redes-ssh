#!/usr/bin/env bash
set -euo pipefail
#
# apagar-aula.sh — apaga a instancia Hetzner de um grupo (servidor + chave SSH).
#
# Uso:
#   ./apagar-aula.sh <nome-do-grupo>
#
# Exemplo:
#   ./apagar-aula.sh grupo-cobrinha

ENV_FILE="${HETZNER_ENV_FILE:-/Users/tardelli/Workplace/hackathon-servers/.env}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEYS_DIR="$SCRIPT_DIR/keys"

# Usa HETZNER_API_TOKEN do ambiente se ja estiver definido; senao tenta o .env
if [[ -z "${HETZNER_API_TOKEN:-}" && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi
[[ -z "${HETZNER_API_TOKEN:-}" ]] && { echo "Erro: HETZNER_API_TOKEN nao definido"; exit 1; }
[[ $# -lt 1 ]] && { echo "Uso: $0 <nome-do-grupo>"; exit 1; }

SLUG=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
NAME="aula-${SLUG}"

api() {
  curl -s -X "$1" "https://api.hetzner.cloud/v1${2}" \
    -H "Authorization: Bearer $HETZNER_API_TOKEN"
}

echo "Apagando servidor \"$NAME\"..."

SERVER_ID=$(api GET "/servers?name=${NAME}" | python3 -c "
import sys,json
s=json.load(sys.stdin).get('servers',[])
print(s[0]['id'] if s else '')
" 2>/dev/null)

if [[ -n "$SERVER_ID" ]]; then
  api DELETE "/servers/${SERVER_ID}" > /dev/null
  echo "  -> Servidor apagado (ID $SERVER_ID)"
else
  echo "  -> Nenhum servidor com nome $NAME encontrado"
fi

KEY_ID=$(api GET "/ssh_keys?name=${NAME}" | python3 -c "
import sys,json
k=json.load(sys.stdin).get('ssh_keys',[])
print(k[0]['id'] if k else '')
" 2>/dev/null)

if [[ -n "$KEY_ID" ]]; then
  api DELETE "/ssh_keys/${KEY_ID}" > /dev/null
  echo "  -> Chave SSH removida da Hetzner (ID $KEY_ID)"
fi

# remove a chave local (opcional)
if [[ -f "$KEYS_DIR/aula-${SLUG}" ]]; then
  rm -f "$KEYS_DIR/aula-${SLUG}" "$KEYS_DIR/aula-${SLUG}.pub"
  echo "  -> Chave local removida"
fi

echo "Pronto."
