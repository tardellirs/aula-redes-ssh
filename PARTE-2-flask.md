# Parte 2 — Colocando o site (cobrinha) no ar

Objetivo: pegar o **jogo da cobrinha** que vocês já fizeram e colocá-lo rodando
**no servidor**, acessível pela internet, com o **nome do grupo** na página.

O material da aula está no **GitHub** do professor. No servidor, vocês vão **clonar**
(baixar) o repositório direto do GitHub — é assim que se leva código para um servidor
no mundo real. A cobrinha fica dentro da pasta `app`:

```
aula-redes-ssh/          <- o repositório da aula (será clonado)
├── PARTE-1-ssh.md
├── PARTE-2-flask.md
├── ...
└── app/                 <- A COBRINHA FICA AQUI
    ├── main.py          <- o programa Flask (aqui ficam os nomes do grupo)
    ├── requirements.txt
    ├── Dockerfile       <- usaremos na Parte 3
    └── templates/
        └── index.html   <- o jogo da cobrinha
```

---

## Passo 1 — Entrar no servidor

No PowerShell (troque `SEU_IP`):

```
ssh -p 53 root@SEU_IP
```

Digite a senha do grupo.

## Passo 2 — Clonar o projeto do GitHub

Já dentro do servidor, baixe o projeto:

```
git clone https://github.com/tardellirs/aula-redes-ssh.git
```

Entre na pasta da cobrinha (dentro do repositório) e veja o conteúdo:

```
cd aula-redes-ssh/app
ls
```

Você deve ver `main.py`, `templates`, `Dockerfile`, etc.

> 💡 `git clone` baixa uma cópia do repositório. É o jeito mais comum de levar código
> para um servidor: em vez de copiar arquivo por arquivo, você "puxa" do GitHub.

## Passo 3 — Instalar o Flask

```
apt install -y python3-flask
```

## Passo 4 — Colocar o nome do grupo

Abra o `main.py` para editar:

```
nano main.py
```

Procure a lista `integrantes` e troque pelos nomes do seu grupo:

```python
integrantes = [
    "Maria Silva",
    "João Souza",
    "Ana Pereira",
]
```

Salve com `Ctrl + O`, Enter, e saia com `Ctrl + X`.

> 💡 Repare: os nomes ficam no **Python** (`main.py`), não no HTML. É o Flask
> (o *backend*) que monta a página com esses nomes antes de enviar pro navegador.

## Passo 5 — Rodar na porta 5000

```
python3 main.py
```

Vai aparecer algo como `Running on http://0.0.0.0:5000`. Agora, **no navegador**,
acesse (troque `SEU_IP`):

```
http://SEU_IP:5000
```

Deve aparecer a cobrinha com os nomes do grupo! 🐍

> ⚠️ Se o navegador **não abrir** na porta 5000, sem problema: a rede do IFSP pode
> estar bloqueando a porta 5000 (assim como bloqueia a 22 do SSH). **Pule para o
> Passo 6**, que usa a porta 80 — essa funciona.

Para parar o servidor, volte ao terminal e aperte `Ctrl + C`.

## Passo 6 — Rodar na porta 80 (a porta padrão da web)

```
PORT=80 python3 main.py
```

Agora acesse no navegador **sem digitar a porta**:

```
http://SEU_IP
```

> 🤔 **Percebeu?** Não precisou digitar `:80`! Isso porque **80 é a porta padrão
> da web** — todo navegador tenta a 80 automaticamente. Por isso sites como
> `google.com` não mostram número de porta na barra de endereço.

## Passo 7 — O problema! 🔌

Com o site rodando na porta 80, faça o teste:

1. Confirme que `http://SEU_IP` está funcionando no navegador.
2. Agora vamos sair do terminal, aperte **`Ctrl + C`** e depois digite
   **`exit`** (para encerrar a conexão SSH com o servidor).
3. Volte ao navegador e **atualize** a página `http://SEU_IP`.

❌ **O site caiu!** Por quê?

Porque o `python3 main.py` só roda **enquanto o seu terminal está aberto e
conectado**. Quando você fecha o SSH, o programa morre junto. Ou seja: do jeito que
fizemos, o site só fica no ar se você ficar com o computador ligado e conectado o
tempo todo — o que não serve para um site de verdade.

> 👉 Na **Parte 3** vamos resolver isso com **contêineres**: o site vai continuar no
> ar sozinho, mesmo depois que você desconectar e até se o servidor reiniciar.

---

## ✅ Checklist da Parte 2

- [ ] Entrei no servidor com `ssh -p 53 root@IP`
- [ ] Clonei o projeto do GitHub com `git clone`
- [ ] Instalei o Flask no servidor com `apt`
- [ ] Coloquei o nome do grupo no `main.py`
- [ ] Rodei na porta 5000 e tentei acessar `http://IP:5000`
- [ ] Rodei na porta 80 e acessei `http://IP` (sem digitar a porta)
- [ ] Entendi por que o site cai quando fecho o SSH
