#!/usr/bin/env bash
set -euo pipefail
#
# listar-grupos.sh — lista os servidores de aula (aula-*) nos DOIS provedores
# (Hetzner e DigitalOcean) com grupo, IP, provedor, tipo, status, se o site
# esta no ar e a senha de cada grupo.
#
# Uso:
#   ./listar-grupos.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${HETZNER_ENV_FILE:-/Users/tardelli/Workplace/hackathon-servers/.env}"
SENHAS_FILE="$SCRIPT_DIR/keys/senhas.csv"

if [[ ( -z "${HETZNER_API_TOKEN:-}" || -z "${DIGITALOCEAN_API_TOKEN:-}" ) && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi
[[ -z "${HETZNER_API_TOKEN:-}" ]] && { echo "Erro: HETZNER_API_TOKEN nao definido"; exit 1; }

HETZNER_JSON=$(curl -s --max-time 20 "https://api.hetzner.cloud/v1/servers?per_page=50" -H "Authorization: Bearer $HETZNER_API_TOKEN")
DO_JSON="{}"
if [[ -n "${DIGITALOCEAN_API_TOKEN:-}" ]]; then
  DO_JSON=$(curl -s --max-time 20 "https://api.digitalocean.com/v2/droplets?per_page=200" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN")
fi

HETZNER_API_TOKEN="" DIGITALOCEAN_API_TOKEN="" \
HETZNER_JSON="$HETZNER_JSON" DO_JSON="$DO_JSON" SENHAS_FILE="$SENHAS_FILE" \
python3 - <<'PYEOF'
import json, os, urllib.request

def load(env):
    try: return json.loads(os.environ.get(env, "{}") or "{}")
    except Exception: return {}

# senhas: slug -> (grupo, senha)
senhas = {}
sf = os.environ["SENHAS_FILE"]
if os.path.exists(sf):
    with open(sf) as f:
        for line in f:
            p = line.rstrip("\n").split(",")
            if len(p) >= 3:
                senhas[p[0]] = (p[1], p[2])

def site_up(ip):
    try:
        with urllib.request.urlopen(urllib.request.Request(f"http://{ip}", method="GET"), timeout=4) as r:
            return r.status == 200
    except Exception:
        return False

rows = []

# Hetzner
for s in load("HETZNER_JSON").get("servers", []):
    if not s.get("name", "").startswith("aula-"): continue
    slug = s["name"][len("aula-"):]
    ip = s.get("public_net", {}).get("ipv4", {}).get("ip", "?")
    rows.append([slug, ip, "hetzner", s.get("server_type", {}).get("name", "?"), s.get("status", "?")])

# DigitalOcean
for d in load("DO_JSON").get("droplets", []):
    if not d.get("name", "").startswith("aula-"): continue
    slug = d["name"][len("aula-"):]
    ip = next((x["ip_address"] for x in d.get("networks", {}).get("v4", []) if x.get("type") == "public"), "?")
    rows.append([slug, ip, "digitalocean", d.get("size_slug", "?"), d.get("status", "?")])

if not rows:
    print("Nenhum servidor de aula (aula-*) encontrado.")
    raise SystemExit(0)

final = []
for slug, ip, prov, stype, status in sorted(rows, key=lambda r: r[0]):
    grupo, senha = senhas.get(slug, (slug, "(= nome do grupo)"))
    ativo = status in ("running", "active")
    site = "no ar" if (ativo and ip != "?" and site_up(ip)) else "fora"
    final.append((grupo, ip, prov, stype, status, site, senha))

headers = ("GRUPO", "IP", "PROVEDOR", "TIPO", "STATUS", "SITE", "SENHA")
cols = list(zip(headers, *final))
widths = [max(len(str(c)) for c in col) for col in cols]
fmt = lambda r: "  ".join(str(v).ljust(w) for v, w in zip(r, widths))
print()
print(fmt(headers))
print("  ".join("-" * w for w in widths))
for r in final:
    print(fmt(r))
print(f"\nTotal: {len(final)} servidor(es). SSH: ssh -p 53 root@<IP>")
PYEOF
