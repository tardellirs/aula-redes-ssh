# Aula — SSH, Flask e Contêineres na nuvem

![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-3.0-000000?logo=flask&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Dockerfile-2496ED?logo=docker&logoColor=white)
![Hetzner](https://img.shields.io/badge/Hetzner-Cloud-D50C2D?logo=hetzner&logoColor=white)
![DigitalOcean](https://img.shields.io/badge/DigitalOcean-Cloud-0080FF?logo=digitalocean&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow)

Atividade prática de **Redes de Computadores** (IFSP Jacareí): os alunos pegam um
jogo da cobrinha feito em **Flask** e colocam no ar em um **servidor real na nuvem**
(Hetzner/DigitalOcean), aprendendo no caminho **SSH**, **deploy** e **contêineres (Docker)**.

> Material livre para reuso por outros professores. Sinta-se à vontade para adaptar.

## As três partes (handouts dos alunos)

1. **[PARTE-1-ssh.md](PARTE-1-ssh.md)** — Conectar via SSH (Windows/PowerShell),
   comandos básicos do Linux e o que é uma chave SSH.
2. **[PARTE-2-flask.md](PARTE-2-flask.md)** — Clonar o projeto, rodar com
   `python3 main.py` (portas 5000 e 80) e descobrir que o site cai ao desconectar.
3. **[PARTE-3-conteiner.md](PARTE-3-conteiner.md)** — Colocar no ar de verdade com
   Docker, que continua rodando sozinho.

Cada parte tem **checkpoints numerados** (`📸 Entrega N` / `✍️ Entrega N`) — 16 no
total. Os alunos registram os prints/respostas na **[FOLHA-DE-ENTREGA.docx](FOLHA-DE-ENTREGA.docx)**
e entregam ao final.

O guia do professor (preparação, tempos, custos, gabarito e solução de problemas)
está em **[PLANO-DA-AULA.md](PLANO-DA-AULA.md)**.

## Website jogo da cobrinha

O sistema que vai ao ar está na pasta [`app/`](app/): um Flask que serve o jogo da
cobrinha e mostra os nomes do grupo (lista `integrantes` em `main.py`).

Os alunos clonam o repositório no servidor e entram na pasta:

```bash
git clone https://github.com/tardellirs/aula-redes-ssh.git
cd aula-redes-ssh/app
```

## Provisionamento dos servidores (professor)

Cada grupo recebe um servidor. **Hetzner por padrão**; se a conta Hetzner já estiver
no limite (10 servidores), cai automaticamente para o **DigitalOcean**. Configure os
tokens e provisione:

```bash
# tokens no ambiente, ou em um .env apontado por HETZNER_ENV_FILE
export HETZNER_API_TOKEN=seu_token
export DIGITALOCEAN_API_TOKEN=seu_token   # usado só no fallback

./provisionar-grupo.sh grupo1     # cria aula-grupo1, senha "grupo1"
./provisionar-grupo.sh grupo2
# ...

./listar-grupos.sh                # lista grupos (Hetzner + DO), IPs, status, site e senhas
./apagar-grupo.sh grupo1          # apaga (procura nos dois provedores)
```

O script cria a instância (Hetzner CX23 → CX33 → CPX22, ou DO `s-2vcpu-2gb`), habilita
**SSH na porta 53** (a 22 costuma ser bloqueada em redes institucionais), define
**login por senha**, instala **Docker** e libera a **porta 80**.

> O limite Hetzner pode ser ajustado com `HETZNER_LIMIT=N ./provisionar-grupo.sh ...`
> (útil para testar o fallback). A conta DigitalOcean tem limite próprio de droplets.

## Aviso

A pasta `keys/` (chaves SSH privadas) e qualquer `.env` **não** vão para o
repositório (veja o `.gitignore`).

## Licença

Distribuído sob a licença **MIT** — veja o arquivo [LICENSE](LICENSE). Use, adapte e
compartilhe à vontade.
