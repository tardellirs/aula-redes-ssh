#!/usr/bin/env bash
set -euo pipefail
#
# provisionar-grupo.sh — cria UMA instancia para um grupo da aula.
#
# Provedor: Hetzner por padrao. Se a conta Hetzner ja estiver no limite
# (HETZNER_LIMIT=10 servidores), cai automaticamente para o DigitalOcean.
#
# O que faz (em qualquer provedor):
#   1. Cria o servidor (Hetzner: CX23->CX33->CPX22 | DO: s-2vcpu-2gb)
#   2. Habilita SSH tambem na porta 53 (a 22 e bloqueada na rede do IFSP)
#   3. Habilita login por SENHA e define a senha do grupo
#   4. Instala Docker + pip + git
#   5. Libera a porta 80 (o site e acessado por http://IP)
#
# Uso:
#   ./provisionar-grupo.sh <nome-do-grupo> [senha]
#
# A senha e opcional: se nao informar, usa o proprio nome do grupo.
# Exemplos:
#   ./provisionar-grupo.sh grupo1            # aula-grupo1, senha "grupo1"
#   ./provisionar-grupo.sh cobrinhas senha42 # senha personalizada
#
# Para apagar depois: ./apagar-grupo.sh <nome-do-grupo>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${HETZNER_ENV_FILE:-/Users/tardelli/Workplace/hackathon-servers/.env}"
KEYS_DIR="$SCRIPT_DIR/keys"
SSH_PORT="53"

# Hetzner
HETZNER_LIMIT="${HETZNER_LIMIT:-10}"   # acima disso, cai pro DigitalOcean
HETZNER_LOCATION="fsn1"
HETZNER_IMAGE="ubuntu-24.04"
SERVER_TYPES=(cx23 cx33 cpx22)
# DigitalOcean (fallback)
DO_REGION="nyc3"
DO_SIZE="s-2vcpu-2gb"
DO_IMAGE="ubuntu-24-04-x64"

# --- carrega tokens (ambiente ou .env) ---
if [[ -z "${HETZNER_API_TOKEN:-}" || -z "${DIGITALOCEAN_API_TOKEN:-}" ]]; then
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  fi
fi
[[ -z "${HETZNER_API_TOKEN:-}" ]] && { echo "Erro: HETZNER_API_TOKEN nao definido (ambiente ou $ENV_FILE)"; exit 1; }

[[ $# -lt 1 ]] && { echo "Uso: $0 <nome-do-grupo> [senha]"; exit 1; }
GROUP_NAME="$1"
SLUG=$(echo "$GROUP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
NAME="aula-${SLUG}"
PASSWORD="${2:-$SLUG}"

# --- helpers de API ---
hapi() { # hapi <metodo> <caminho> [json]
  local m="$1" p="$2" d="${3:-}"
  if [[ -n "$d" ]]; then
    curl -s -X "$m" "https://api.hetzner.cloud/v1${p}" -H "Authorization: Bearer $HETZNER_API_TOKEN" -H "Content-Type: application/json" -d "$d"
  else
    curl -s -X "$m" "https://api.hetzner.cloud/v1${p}" -H "Authorization: Bearer $HETZNER_API_TOKEN"
  fi
}
doapi() { # doapi <metodo> <caminho> [json]
  local m="$1" p="$2" d="${3:-}"
  if [[ -n "$d" ]]; then
    curl -s -X "$m" "https://api.digitalocean.com/v2${p}" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN" -H "Content-Type: application/json" -d "$d"
  else
    curl -s -X "$m" "https://api.digitalocean.com/v2${p}" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN"
  fi
}

# --- decide o provedor (Hetzner, ou DO se a Hetzner estiver no limite) ---
HCOUNT=$(hapi GET "/servers?per_page=50" | python3 -c "import sys,json;print(len(json.load(sys.stdin).get('servers',[])))" 2>/dev/null || echo 0)
if [[ "$HCOUNT" -lt "$HETZNER_LIMIT" ]]; then
  PROVIDER="hetzner"
else
  PROVIDER="digitalocean"
  [[ -z "${DIGITALOCEAN_API_TOKEN:-}" ]] && { echo "Erro: Hetzner no limite ($HCOUNT) e DIGITALOCEAN_API_TOKEN nao definido"; exit 1; }
fi

echo "============================================"
echo "  Provisionamento de aula"
echo "============================================"
echo "  Grupo:    $GROUP_NAME"
echo "  Servidor: $NAME"
echo "  Hetzner:  $HCOUNT/$HETZNER_LIMIT servidores"
echo "  Provedor: $PROVIDER"
echo "============================================"
echo

# --- 1. chave SSH local ---
mkdir -p "$KEYS_DIR"
KEY="$KEYS_DIR/aula-${SLUG}"
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "aula-${SLUG}" -q
  echo "[1/4] Chave SSH gerada: $KEY"
else
  echo "[1/4] Chave SSH ja existe: $KEY"
fi
PUBKEY=$(cat "${KEY}.pub")

SERVER_IP=""
USED_TYPE=""

if [[ "$PROVIDER" == "hetzner" ]]; then
  # registra chave na Hetzner
  KEY_RESP=$(hapi POST "/ssh_keys" "{\"name\":\"${NAME}\",\"public_key\":\"${PUBKEY}\"}")
  KEY_ID=$(echo "$KEY_RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'ssh_key' in d: print(d['ssh_key']['id'])
elif d.get('error',{}).get('code')=='uniqueness_error': print('EXISTS')
else: print('')
" 2>/dev/null)
  [[ "$KEY_ID" == "EXISTS" ]] && KEY_ID=$(hapi GET "/ssh_keys?name=${NAME}" | python3 -c "import sys,json; print(json.load(sys.stdin)['ssh_keys'][0]['id'])")
  [[ -z "$KEY_ID" ]] && { echo "Erro ao registrar chave SSH:"; echo "$KEY_RESP"; exit 1; }

  for TYPE in "${SERVER_TYPES[@]}"; do
    echo "[2/4] Hetzner: tentando tipo $TYPE em $HETZNER_LOCATION..."
    RESP=$(hapi POST "/servers" "{\"name\":\"${NAME}\",\"server_type\":\"${TYPE}\",\"image\":\"${HETZNER_IMAGE}\",\"location\":\"${HETZNER_LOCATION}\",\"start_after_create\":true,\"ssh_keys\":[${KEY_ID}]}")
    SERVER_IP=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('server',{}).get('public_net',{}).get('ipv4',{}).get('ip','') or '')" 2>/dev/null)
    if [[ -n "$SERVER_IP" && "$SERVER_IP" != "None" ]]; then USED_TYPE="$TYPE"; echo "  -> Criado ($TYPE): $SERVER_IP"; break; fi
    echo "  -> Falhou ($TYPE): $(echo "$RESP" | python3 -c "import sys,json;print(json.load(sys.stdin).get('error',{}).get('message','?'))" 2>/dev/null)"
  done
  [[ -z "$SERVER_IP" ]] && { echo "Erro: nenhum tipo Hetzner disponivel."; exit 1; }

else
  # --- DigitalOcean ---
  KEY_ID=$(doapi POST "/account/keys" "{\"name\":\"${NAME}\",\"public_key\":\"${PUBKEY}\"}" | python3 -c "import sys,json;d=json.load(sys.stdin);print((d.get('ssh_key') or {}).get('id',''))" 2>/dev/null)
  [[ -z "$KEY_ID" ]] && KEY_ID=$(doapi GET "/account/keys" | python3 -c "import sys,json;print(next((k['id'] for k in json.load(sys.stdin).get('ssh_keys',[]) if k['name']=='${NAME}'),''))" 2>/dev/null)
  [[ -z "$KEY_ID" ]] && { echo "Erro ao registrar chave SSH no DO"; exit 1; }

  echo "[2/4] DigitalOcean: criando droplet $DO_SIZE em $DO_REGION..."
  DROP=$(doapi POST "/droplets" "{\"name\":\"${NAME}\",\"region\":\"${DO_REGION}\",\"size\":\"${DO_SIZE}\",\"image\":\"${DO_IMAGE}\",\"ssh_keys\":[${KEY_ID}]}")
  DID=$(echo "$DROP" | python3 -c "import sys,json;d=json.load(sys.stdin);print((d.get('droplet') or {}).get('id',''))" 2>/dev/null)
  [[ -z "$DID" ]] && { echo "Erro ao criar droplet:"; echo "$DROP" | head -3; exit 1; }
  USED_TYPE="$DO_SIZE"
  echo "  -> Droplet criado (id $DID), aguardando IP..."
  for i in $(seq 1 30); do
    D=$(doapi GET "/droplets/$DID")
    ST=$(echo "$D" | python3 -c "import sys,json;print(json.load(sys.stdin)['droplet']['status'])" 2>/dev/null)
    SERVER_IP=$(echo "$D" | python3 -c "import sys,json;n=json.load(sys.stdin)['droplet']['networks']['v4'];print(next((x['ip_address'] for x in n if x['type']=='public'),''))" 2>/dev/null)
    [[ "$ST" == "active" && -n "$SERVER_IP" ]] && { echo "  -> Ativo: $SERVER_IP"; break; }
    sleep 8
  done
  [[ -z "$SERVER_IP" ]] && { echo "Erro: droplet nao ficou ativo."; exit 1; }
fi

# --- 3. espera o SSH (porta 22, root) ---
echo "[3/4] Aguardando SSH..."
ssh-keygen -R "$SERVER_IP" 2>/dev/null || true
SSH_OPTS="-i $KEY -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"
for i in $(seq 1 60); do
  ssh $SSH_OPTS "root@${SERVER_IP}" "echo ok" &>/dev/null && { echo "  -> SSH disponivel"; break; }
  sleep 5
  [[ $i -eq 60 ]] && { echo "Erro: SSH nao respondeu em 5 min"; exit 1; }
done

# --- 4. configura porta 53 + Docker + porta 80 (robusto p/ Hetzner e DO) ---
echo "[4/4] Configurando porta 53, Docker e firewall..."
ssh $SSH_OPTS "root@${SERVER_IP}" "bash -s" <<'SETUP'
set -e
export DEBIAN_FRONTEND=noninteractive
# Evita travas de apt no 1o boot (apt-daily + droplet-agent do DO competindo pelo lock)
systemctl stop apt-daily.timer apt-daily-upgrade.timer apt-news.timer 2>/dev/null || true
systemctl mask apt-daily.service apt-daily-upgrade.service apt-news.service unattended-upgrades.service 2>/dev/null || true
# SSH tambem na porta 53 (a 22 e bloqueada no IFSP)
systemctl disable --now ssh.socket 2>/dev/null || true
systemctl enable ssh 2>/dev/null || true
mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nDNSStubListener=no\n' > /etc/systemd/resolved.conf.d/nostub.conf
systemctl restart systemd-resolved 2>/dev/null || true
grep -q "^Port 22" /etc/ssh/sshd_config || echo "Port 22" >> /etc/ssh/sshd_config
grep -q "^Port 53" /etc/ssh/sshd_config || echo "Port 53" >> /etc/ssh/sshd_config
systemctl restart ssh
echo "  -> SSH nas portas 22 e 53"
# Docker/pip/git. O apt ESPERA o lock (DPkg::Lock::Timeout) e nao pendura em mirror ruim (Acquire timeouts).
APT="apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20 -y -qq"
$APT update >/dev/null 2>&1
$APT install docker.io python3-pip git >/dev/null 2>&1
systemctl enable docker >/dev/null 2>&1
systemctl start docker
echo "  -> Docker: $(docker --version | cut -d, -f1); $(git --version)"
# firewall: ufw normalmente inativo; se ativo, libera 53 e 80
if ufw status 2>/dev/null | grep -q "Status: active"; then ufw allow 53/tcp >/dev/null; ufw allow 80/tcp >/dev/null; fi
echo "  -> Porta 80 liberada"
SETUP

# --- senha do grupo + login por senha ---
echo "  Habilitando login por senha (senha: $PASSWORD)..."
ssh $SSH_OPTS "root@${SERVER_IP}" "bash -s" <<SETUP_PWD
set -e
echo 'root:${PASSWORD}' | chpasswd
mkdir -p /etc/ssh/sshd_config.d
printf 'PermitRootLogin yes\nPasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/00-aula.conf
sed -ri 's/^#?\s*PasswordAuthentication\s+no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config 2>/dev/null || true
systemctl restart ssh
echo "  -> Login por senha habilitado"
SETUP_PWD

# --- registra no senhas.csv: slug,grupo,senha,provedor (keys/ e gitignored) ---
SENHAS_FILE="$KEYS_DIR/senhas.csv"
touch "$SENHAS_FILE"
grep -v "^${SLUG}," "$SENHAS_FILE" > "${SENHAS_FILE}.tmp" 2>/dev/null || true
mv "${SENHAS_FILE}.tmp" "$SENHAS_FILE"
echo "${SLUG},${GROUP_NAME},${PASSWORD},${PROVIDER}" >> "$SENHAS_FILE"

# --- resumo ---
echo
echo "============================================"
echo "  Pronto! Servidor do grupo \"$GROUP_NAME\""
echo "============================================"
echo "  Provedor: $PROVIDER ($USED_TYPE)"
echo "  IP:       $SERVER_IP"
echo "  Site:     http://$SERVER_IP   (depois que o grupo subir o app)"
echo
echo "  --- Entregue ISTO para o grupo ---"
echo "  Comando de acesso (porta 53):"
echo "    ssh -p ${SSH_PORT} root@${SERVER_IP}"
echo "  Senha: ${PASSWORD}"
echo
echo "  (chave de administrador do professor: $KEY)"
echo "============================================"
