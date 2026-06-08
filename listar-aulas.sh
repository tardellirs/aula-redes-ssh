#!/usr/bin/env bash
set -euo pipefail
#
# listar-aulas.sh — lista todos os servidores de aula (aula-*) com grupo, IP,
# tipo, status, se o site esta no ar e a senha de cada grupo.
#
# Uso:
#   ./listar-aulas.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${HETZNER_ENV_FILE:-/Users/tardelli/Workplace/hackathon-servers/.env}"
SENHAS_FILE="$SCRIPT_DIR/keys/senhas.csv"

# Usa HETZNER_API_TOKEN do ambiente se ja estiver definido; senao tenta o .env
if [[ -z "${HETZNER_API_TOKEN:-}" && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi
[[ -z "${HETZNER_API_TOKEN:-}" ]] && { echo "Erro: HETZNER_API_TOKEN nao definido"; exit 1; }

SERVERS_JSON=$(curl -s "https://api.hetzner.cloud/v1/servers?per_page=50" \
  -H "Authorization: Bearer $HETZNER_API_TOKEN")

HETZNER_API_TOKEN="" \
SERVERS_JSON="$SERVERS_JSON" \
SENHAS_FILE="$SENHAS_FILE" \
python3 - <<'PYEOF'
import json, os, urllib.request

data = json.loads(os.environ["SERVERS_JSON"])
servers = [s for s in data.get("servers", []) if s.get("name", "").startswith("aula-")]

# carrega senhas: slug -> (grupo, senha)
senhas = {}
sf = os.environ["SENHAS_FILE"]
if os.path.exists(sf):
    with open(sf) as f:
        for line in f:
            parts = line.rstrip("\n").split(",", 2)
            if len(parts) == 3:
                senhas[parts[0]] = (parts[1], parts[2])

def site_up(ip):
    try:
        req = urllib.request.Request(f"http://{ip}", method="GET")
        with urllib.request.urlopen(req, timeout=4) as r:
            return r.status == 200
    except Exception:
        return False

if not servers:
    print("Nenhum servidor de aula (aula-*) encontrado.")
    raise SystemExit(0)

rows = []
for s in sorted(servers, key=lambda x: x["name"]):
    slug = s["name"][len("aula-"):]
    ip = s.get("public_net", {}).get("ipv4", {}).get("ip", "?")
    stype = s.get("server_type", {}).get("name", "?")
    status = s.get("status", "?")
    grupo, senha = senhas.get(slug, (slug, "(= nome do grupo)"))
    site = "no ar" if (status == "running" and site_up(ip)) else "fora"
    rows.append((grupo, ip, stype, status, site, senha))

# largura das colunas
headers = ("GRUPO", "IP", "TIPO", "STATUS", "SITE", "SENHA")
cols = list(zip(headers, *rows)) if rows else []
widths = [max(len(str(c)) for c in col) for col in cols]

def fmt(r):
    return "  ".join(str(v).ljust(w) for v, w in zip(r, widths))

print()
print(fmt(headers))
print("  ".join("-" * w for w in widths))
for r in rows:
    print(fmt(r))
print(f"\nTotal: {len(rows)} servidor(es). SSH: ssh -p 53 root@<IP>")
PYEOF
