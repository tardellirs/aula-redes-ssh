# Parte 3 — Deixando o site no ar com contêiner (Docker)

Na Parte 2 vimos o problema: o site cai quando fechamos o SSH. Vamos resolver isso
com **contêineres**.

## O que é um contêiner?

Um **contêiner** é um ambiente isolado que empacota a aplicação **junto com todas as
suas dependências** (o interpretador Python, bibliotecas como o Flask, os arquivos do
projeto e as configurações). Com isso, o contêiner:

- executa de forma **isolada e em segundo plano** (não depende do seu terminal aberto);
- **continua em execução** mesmo depois que você encerra a conexão SSH;
- pode ser configurado para **reiniciar automaticamente** caso o servidor reinicie;
- garante **portabilidade**: como o contêiner carrega tudo o que precisa, se a
  aplicação roda na sua máquina ela roda **igual em qualquer outro ambiente** — outro
  computador ou um servidor Linux na nuvem. É o que resolve o clássico problema do
  *"na minha máquina funciona"*.

O **Docker** é a ferramenta que cria e gerencia esses contêineres (já está instalado
no servidor).

> 📦 No projeto há um arquivo chamado `Dockerfile`: é a **definição da imagem** — ele
> descreve, passo a passo, como o contêiner é construído (qual imagem base usar, o que
> instalar e qual comando executar).

---

## Passo 1 — Entrar no servidor e ir até o projeto

```
ssh -p 53 root@SEU_IP
cd aula-redes-ssh/app
```

> Se na Parte 2 o site ainda estiver rodando, garanta que ele parou:
> ```
> pkill -f main.py
> ```

## Passo 2 — Construir a imagem

```
docker build -t cobrinha .
```

- `-t cobrinha` = dá o nome "cobrinha" para a imagem
- `.` = use o `Dockerfile` desta pasta

Isso baixa o Python, instala o Flask e empacota o projeto. Demora um pouquinho na
primeira vez.

> 📸 **Entrega 11** — Print do final do `docker build` (as linhas `Successfully built`
> / `Successfully tagged`).

## Passo 3 — Rodar o contêiner

```
docker run -d --name cobrinha --restart unless-stopped -p 80:5000 cobrinha
```

Entendendo cada parte:

| Pedaço | Significado |
|---|---|
| `-d` | roda em segundo plano (*detached*) — libera seu terminal |
| `--name cobrinha` | dá um nome ao contêiner (pra gente se referir a ele depois) |
| `--restart unless-stopped` | se cair ou o servidor reiniciar, ele **volta sozinho** |
| `-p 80:5000` | liga a porta **80 do servidor** à porta **5000 dentro do contêiner** |
| `cobrinha` | qual imagem rodar (a que criamos no passo 2) |

> 💡 O `-p 80:5000` é a parte mais importante: por fora, o mundo acessa pela porta 80
> (`http://SEU_IP`); por dentro, o Flask continua na 5000. O Docker faz a "ponte".

> 📸 **Entrega 12** — Print do `docker ps` mostrando o contêiner `cobrinha` com
> status `Up`.

## Passo 4 — O resultado

1. Acesse `http://SEU_IP` no navegador — a cobrinha está lá.
2. Agora **saia do servidor**:
   ```
   exit
   ```
3. Pode até **fechar o PowerShell**.
4. Atualize `http://SEU_IP` no navegador.

✅ **O site continua no ar!** Diferente da Parte 2, agora ele não depende do seu
terminal: o contêiner permanece em execução no servidor, 24 horas por dia.

> 📸 **Entrega 13** — Print de `http://SEU_IP` **depois** de ter dado `exit` — provando
> que, com o contêiner, o site continua no ar mesmo sem você conectado.

---

## Passo 5 — Comandos para gerenciar contêineres

Conecte de novo (`ssh -p 53 root@SEU_IP`) e experimente cada comando:

```
docker ps                  # lista os contêineres RODANDO
docker ps -a               # lista TODOS (inclusive os parados)
docker images              # lista as imagens (os modelos usados para criar contêineres)
```

### Ver o que está acontecendo dentro

```
docker logs cobrinha       # mostra os logs (cada acesso ao site aparece aqui)
docker logs -f cobrinha    # acompanha ao vivo (atualize o site e veja!). Ctrl+C para sair
docker stats               # uso de CPU/memória em tempo real. Ctrl+C para sair
```

> 📸 **Entrega 14** — Print do `docker logs cobrinha` (mostrando os acessos ao site)
> **ou** do `docker stats`.

### Ligar, desligar, reiniciar

```
docker stop cobrinha       # PARA o contêiner (o site sai do ar)
docker ps                  # repare: sumiu da lista de "rodando"
docker start cobrinha      # liga de novo
docker restart cobrinha    # reinicia
```

### Entrar DENTRO do contêiner

```
docker exec -it cobrinha sh
```

Você entra no contêiner, que possui seu próprio ambiente Linux isolado. Experimente
`ls`, `pwd`, `cat main.py`. Para sair de dentro do contêiner, digite `exit`.

> 📸 **Entrega 15** — Print de **dentro** do contêiner (depois do
> `docker exec -it cobrinha sh`), mostrando o resultado de `ls` e `cat main.py`.

### Remover

```
docker rm -f cobrinha      # para e remove o contêiner (-f = força)
docker ps -a               # confirme que sumiu
```

---

## (Opcional) Atualizar o site depois de uma mudança

Mudou algo no código (ex: os nomes)? É só remontar e rodar de novo:

```
docker rm -f cobrinha
docker build -t cobrinha .
docker run -d --name cobrinha --restart unless-stopped -p 80:5000 cobrinha
```

---

> ✍️ **Entrega 16 (fechamento)** — Explique com suas palavras: qual a diferença entre
> rodar o site com `python3 main.py` (Parte 2) e com o contêiner Docker (Parte 3)?
> Por que só o segundo continua no ar depois que você desconecta?

---

## ✅ Checklist da Parte 3

- [ ] Construí a imagem com `docker build`
- [ ] Subi o contêiner com `docker run -d ... -p 80:5000`
- [ ] Fechei o SSH e o site **continuou no ar**
- [ ] Usei `docker ps`, `docker logs` e `docker stats`
- [ ] Parei e liguei o contêiner com `docker stop` / `docker start`
- [ ] Entrei dentro do contêiner com `docker exec -it cobrinha sh`
- [ ] Entendi a diferença entre a Parte 2 (cai ao desconectar) e a Parte 3 (fica no ar)

🎉 **Parabéns!** Vocês colocaram um sistema de verdade no ar, do jeito que se faz no
mundo profissional.
