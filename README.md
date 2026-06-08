# Aula — SSH, Flask e Contêineres na nuvem

![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-3.0-000000?logo=flask&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Dockerfile-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow)

Atividade prática de **Redes de Computadores** (IFSP Jacareí): os alunos pegam um
jogo da cobrinha feito em **Flask** e colocam no ar em um **servidor real na nuvem**
(Hetzner), aprendendo no caminho **SSH**, **deploy** e **contêineres (Docker)**.

> Material livre para reuso por outros professores. Sinta-se à vontade para adaptar.

## As três partes (handouts dos alunos)

1. **[PARTE-1-ssh.md](PARTE-1-ssh.md)** — Conectar via SSH (Windows/PowerShell),
   comandos básicos do Linux e o que é uma chave SSH.
2. **[PARTE-2-flask.md](PARTE-2-flask.md)** — Clonar o projeto, rodar com
   `python3 main.py` (portas 5000 e 80) e descobrir que o site cai ao desconectar.
3. **[PARTE-3-conteiner.md](PARTE-3-conteiner.md)** — Colocar no ar de verdade com
   Docker, que continua rodando sozinho.

O guia do professor (preparação, tempos, custos, gabarito e solução de problemas)
está em **[PLANO-DA-AULA.md](PLANO-DA-AULA.md)**.

## A cobrinha

O sistema que vai ao ar está na pasta [`app/`](app/): um Flask que serve o jogo da
cobrinha e mostra os nomes do grupo (lista `integrantes` em `main.py`).

Os alunos clonam o repositório no servidor e entram na pasta:

```bash
git clone https://github.com/tardellirs/aula-redes-ssh.git
cd aula-redes-ssh/app
```

## Provisionamento dos servidores (professor)

Cada grupo recebe um servidor Hetzner. Configure o token e provisione:

```bash
# token da Hetzner: no ambiente, ou em um .env apontado por HETZNER_ENV_FILE
export HETZNER_API_TOKEN=seu_token

./provisionar-aula.sh grupo1     # cria aula-grupo1, senha "grupo1"
./provisionar-aula.sh grupo2
# ...

./apagar-aula.sh grupo1          # apaga depois da aula
```

O script cria a instância (CX23 → CX33 → CPX22), habilita **SSH na porta 53**
(a 22 costuma ser bloqueada em redes institucionais), define **login por senha**,
instala **Docker** e libera a **porta 80**.

## Aviso

A pasta `keys/` (chaves SSH privadas) e qualquer `.env` **não** vão para o
repositório (veja o `.gitignore`).

## Licença

Distribuído sob a licença **MIT** — veja o arquivo [LICENSE](LICENSE). Use, adapte e
compartilhe à vontade.
