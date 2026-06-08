# Cobrinha IFSP — Flask

Jogo da cobrinha em **Flask**, usado na atividade de Redes de Computadores do
IFSP Jacareí para colocar um site no ar em um servidor na nuvem.

## Estrutura

```
.
├── main.py              # servidor Flask (a lista "integrantes" tem os nomes do grupo)
├── templates/
│   └── index.html       # o jogo da cobrinha
├── Dockerfile           # receita do contêiner
└── requirements.txt
```

## Como usar (resumo)

No servidor, depois de clonar este repositório:

```bash
# rodar direto (cai quando fecha o SSH):
apt install -y python3-flask
PORT=80 python3 main.py

# rodar como contêiner (fica no ar de verdade):
docker build -t cobrinha .
docker run -d --name cobrinha --restart unless-stopped -p 80:5000 cobrinha
```

Acesse em `http://IP_DO_SERVIDOR`.

> Antes de subir, edite a lista `integrantes` no `main.py` com os nomes do grupo.
