#!/usr/bin/env bash
set -euo pipefail
#
# provisionar-aula.sh — cria UMA instancia Hetzner para um grupo da aula.
#
# O que faz:
#   1. Cria um servidor na Hetzner (tenta CX23 -> CX33 -> CPX22, o mais barato disponivel)
#   2. Habilita o SSH tambem na porta 53 (a porta 22 e bloqueada na rede do IFSP)
#   3. Habilita login por SENHA (mais simples para os alunos) e define a senha do grupo
#   4. Pre-instala o Docker (a Parte 3 da atividade usa conteineres)
#   5. Libera a porta 80 (o site sera acessado por http://IP)
#   6. Mostra o comando de acesso (por senha) para o grupo
#
# Uso:
#   ./provisionar-aula.sh <nome-do-grupo> [senha]
#
# A senha e opcional: se nao informar, usa o proprio nome do grupo como senha.
# Padronize os grupos como grupo1, grupo2, ... (a senha vira grupo1, grupo2, ...).
#
# Exemplos:
#   ./provisionar-aula.sh grupo1            # servidor aula-grupo1, senha "grupo1"
#   ./provisionar-aula.sh grupo2            # servidor aula-grupo2, senha "grupo2"
#   ./provisionar-aula.sh cobrinhas senha42 # senha personalizada
#
# Para apagar depois: ./apagar-aula.sh <nome-do-grupo>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Caminho do .env com o HETZNER_API_TOKEN. Pode ser sobrescrito com a variavel
# HETZNER_ENV_FILE, ou basta exportar HETZNER_API_TOKEN direto no ambiente.
ENV_FILE="${HETZNER_ENV_FILE:-/Users/tardelli/Workplace/hackathon-servers/.env}"
KEYS_DIR="$SCRIPT_DIR/keys"
LOCATION="fsn1"
IMAGE="ubuntu-24.04"
SSH_PORT="53"
# Ordem de preferencia de tipo de servidor (do mais barato pro mais caro)
SERVER_TYPES=(cx23 cx33 cpx22)

# --- carrega o token da Hetzner ---
# Se o token ja estiver no ambiente, usa direto; senao tenta o arquivo .env.
if [[ -z "${HETZNER_API_TOKEN:-}" ]]; then
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  else
    echo "Erro: defina HETZNER_API_TOKEN no ambiente ou em $ENV_FILE"
    echo "(ou aponte para outro arquivo com: HETZNER_ENV_FILE=/caminho/.env $0 ...)"
    exit 1
  fi
fi
if [[ -z "${HETZNER_API_TOKEN:-}" ]]; then
  echo "Erro: HETZNER_API_TOKEN nao definido"
  exit 1
fi

[[ $# -lt 1 ]] && { echo "Uso: $0 <nome-do-grupo>"; exit 1; }

GROUP_NAME="$1"
SLUG=$(echo "$GROUP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
NAME="aula-${SLUG}"
# senha do grupo: 2o argumento, ou o proprio slug (ex: grupo1 -> senha "grupo1")
PASSWORD="${2:-$SLUG}"

echo "============================================"
echo "  Provisionamento de aula — Hetzner"
echo "============================================"
echo "  Grupo:    $GROUP_NAME"
echo "  Servidor: $NAME"
echo "============================================"
echo

api() {
  # api <metodo> <caminho> [json]
  local method="$1" path="$2" data="${3:-}"
  if [[ -n "$data" ]]; then
    curl -s -X "$method" "https://api.hetzner.cloud/v1${path}" \
      -H "Authorization: Bearer $HETZNER_API_TOKEN" \
      -H "Content-Type: application/json" -d "$data"
  else
    curl -s -X "$method" "https://api.hetzner.cloud/v1${path}" \
      -H "Authorization: Bearer $HETZNER_API_TOKEN"
  fi
}

# --- 1. chave SSH ---
mkdir -p "$KEYS_DIR"
KEY="$KEYS_DIR/aula-${SLUG}"
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "aula-${SLUG}" -q
  echo "[1/5] Chave SSH gerada: $KEY"
else
  echo "[1/5] Chave SSH ja existe: $KEY"
fi
PUBKEY=$(cat "${KEY}.pub")

KEY_RESP=$(api POST "/ssh_keys" "{\"name\":\"${NAME}\",\"public_key\":\"${PUBKEY}\"}")
KEY_ID=$(echo "$KEY_RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'ssh_key' in d: print(d['ssh_key']['id'])
elif d.get('error',{}).get('code')=='uniqueness_error': print('EXISTS')
else: print('')
" 2>/dev/null)
if [[ "$KEY_ID" == "EXISTS" ]]; then
  KEY_ID=$(api GET "/ssh_keys?name=${NAME}" | python3 -c "import sys,json; print(json.load(sys.stdin)['ssh_keys'][0]['id'])")
fi
[[ -z "$KEY_ID" ]] && { echo "Erro ao registrar chave SSH:"; echo "$KEY_RESP"; exit 1; }

# --- 2. cria o servidor (tenta cada tipo na ordem de preferencia) ---
SERVER_IP=""
USED_TYPE=""
for TYPE in "${SERVER_TYPES[@]}"; do
  echo "[2/5] Tentando criar servidor tipo $TYPE em $LOCATION..."
  RESP=$(api POST "/servers" "{
    \"name\":\"${NAME}\",
    \"server_type\":\"${TYPE}\",
    \"image\":\"${IMAGE}\",
    \"location\":\"${LOCATION}\",
    \"start_after_create\":true,
    \"ssh_keys\":[${KEY_ID}]
  }")
  SERVER_IP=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('server',{}).get('public_net',{}).get('ipv4',{}).get('ip','') or '')" 2>/dev/null)
  if [[ -n "$SERVER_IP" && "$SERVER_IP" != "None" ]]; then
    USED_TYPE="$TYPE"
    echo "  -> Servidor criado ($TYPE): $SERVER_IP"
    break
  fi
  ERR=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error',{}).get('message','?'))" 2>/dev/null)
  echo "  -> Falhou ($TYPE): $ERR"
done
[[ -z "$SERVER_IP" ]] && { echo "Erro: nenhum tipo de servidor disponivel."; exit 1; }

# --- 3. espera o SSH (porta 22, ainda padrao) ---
echo "[3/5] Aguardando SSH ficar disponivel..."
ssh-keygen -R "$SERVER_IP" 2>/dev/null || true
SSH_OPTS="-i $KEY -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"
for i in $(seq 1 60); do
  if ssh $SSH_OPTS "root@${SERVER_IP}" "echo ok" &>/dev/null; then
    echo "  -> SSH disponivel"
    break
  fi
  sleep 5
  [[ $i -eq 60 ]] && { echo "Erro: SSH nao respondeu em 5 min"; exit 1; }
done

# --- 4. configura SSH na porta 53 + instala Docker + libera porta 80 ---
echo "[4/5] Configurando porta 53, Docker e firewall..."
ssh $SSH_OPTS "root@${SERVER_IP}" "bash -s" <<'SETUP'
set -e
export DEBIAN_FRONTEND=noninteractive

# --- SSH tambem na porta 53 ---
# Ubuntu 24.04 usa ssh.socket; desabilita pra poder fixar as portas no sshd
systemctl disable --now ssh.socket 2>/dev/null || true
systemctl enable ssh 2>/dev/null || true
# A porta 53 normalmente esta ocupada pelo systemd-resolved (DNS). Desliga o stub:
mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nDNSStubListener=no\n' > /etc/systemd/resolved.conf.d/nostub.conf
systemctl restart systemd-resolved
# Garante Port 22 e adiciona Port 53
grep -q "^Port 22" /etc/ssh/sshd_config || echo "Port 22" >> /etc/ssh/sshd_config
grep -q "^Port 53" /etc/ssh/sshd_config || echo "Port 53" >> /etc/ssh/sshd_config
systemctl restart ssh
echo "  -> SSH ouvindo nas portas 22 e 53"

# --- Docker ---
cloud-init status --wait 2>/dev/null || true
while fuser /var/lib/apt/lists/lock /var/lib/dpkg/lock-frontend 2>/dev/null; do sleep 2; done
apt-get update -qq
# docker.io -> conteineres (Parte 3); python3-pip -> Flask; git -> clonar o projeto (Parte 2)
apt-get install -y -qq docker.io python3-pip git > /dev/null 2>&1
systemctl enable docker >/dev/null 2>&1
systemctl start docker
echo "  -> Docker instalado: $(docker --version)"
echo "  -> pip instalado: $(pip3 --version | cut -d' ' -f1-2)"

# --- firewall: por padrao o ufw vem inativo na Hetzner (tudo liberado).
#     So garantimos que, se estiver ativo, as portas 53 e 80 estejam abertas.
if ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw allow 53/tcp >/dev/null
  ufw allow 80/tcp >/dev/null
fi
echo "  -> Porta 80 liberada para o site"
SETUP

# --- 4b. define a senha do grupo e habilita login por senha ---
echo "[4b] Habilitando login por senha (senha: $PASSWORD)..."
ssh $SSH_OPTS "root@${SERVER_IP}" "bash -s" <<SETUP_PWD
set -e
echo 'root:${PASSWORD}' | chpasswd
# habilita login por senha (sobrescreve o que o cloud-init deixou).
# 00- ordena ANTES do 50-cloud-init.conf e o sshd usa o primeiro valor encontrado.
mkdir -p /etc/ssh/sshd_config.d
printf 'PermitRootLogin yes\nPasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/00-aula.conf
sed -ri 's/^#?\s*PasswordAuthentication\s+no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config 2>/dev/null || true
systemctl restart ssh
echo "  -> Login por senha habilitado para root"
SETUP_PWD

# --- 4c. registra a senha localmente (keys/ e gitignored) p/ o listar-aulas.sh ---
SENHAS_FILE="$KEYS_DIR/senhas.csv"
touch "$SENHAS_FILE"
# remove linha antiga deste grupo (se existir) e regrava
grep -v "^${SLUG}," "$SENHAS_FILE" > "${SENHAS_FILE}.tmp" 2>/dev/null || true
mv "${SENHAS_FILE}.tmp" "$SENHAS_FILE"
echo "${SLUG},${GROUP_NAME},${PASSWORD}" >> "$SENHAS_FILE"

# --- 5. resumo ---
echo
echo "============================================"
echo "  Pronto! Servidor do grupo \"$GROUP_NAME\""
echo "============================================"
echo "  Tipo:     $USED_TYPE"
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
