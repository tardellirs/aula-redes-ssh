# Parte 3 — Deixando o site no ar com contêiner (Docker)

Na Parte 2 vimos o problema: o site cai quando fechamos o SSH. Vamos resolver isso
com **contêineres**.

## O que é um contêiner?

Um **contêiner** é como uma "caixinha" que empacota o seu programa **junto com tudo
que ele precisa para rodar** (o Python, o Flask, os arquivos...). Essa caixinha:

- roda **sozinha, em segundo plano** (não precisa do seu terminal aberto);
- **continua no ar** mesmo depois que você desconecta;
- pode ser configurada para **voltar sozinha** se o servidor reiniciar.

O **Docker** é o programa que cria e gerencia esses contêineres (já está instalado
no servidor).

> 📦 No projeto há um arquivo chamado `Dockerfile`: é a "receita" que diz ao Docker
> como montar a caixinha (qual base usar, o que instalar, qual comando executar).

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

## Passo 2 — Construir a imagem (montar a caixinha)

```
docker build -t cobrinha .
```

- `-t cobrinha` = dá o nome "cobrinha" para a imagem
- `.` = use o `Dockerfile` desta pasta

Isso baixa o Python, instala o Flask e empacota o projeto. Demora um pouquinho na
primeira vez.

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
| `-p 80:5000` | liga a porta **80 do servidor** à porta **5000 de dentro da caixinha** |
| `cobrinha` | qual imagem rodar (a que criamos no passo 2) |

> 💡 O `-p 80:5000` é a parte mais importante: por fora, o mundo acessa pela porta 80
> (`http://SEU_IP`); por dentro, o Flask continua na 5000. O Docker faz a "ponte".

## Passo 4 — A mágica! ✨

1. Acesse `http://SEU_IP` no navegador — a cobrinha está lá.
2. Agora **saia do servidor**:
   ```
   exit
   ```
3. Pode até **fechar o PowerShell**.
4. Atualize `http://SEU_IP` no navegador.

✅ **O site continua no ar!** Diferente da Parte 2, agora ele não depende do seu
terminal. A caixinha roda sozinha no servidor, 24 horas por dia.

---

## Passo 5 — Comandos para gerenciar contêineres

Conecte de novo (`ssh -p 53 root@SEU_IP`) e experimente cada comando:

```
docker ps                  # lista os contêineres RODANDO
docker ps -a               # lista TODOS (inclusive os parados)
docker images              # lista as imagens (as "caixinhas montadas")
```

### Ver o que está acontecendo dentro

```
docker logs cobrinha       # mostra os logs (cada acesso ao site aparece aqui)
docker logs -f cobrinha    # acompanha ao vivo (atualize o site e veja!). Ctrl+C para sair
docker stats               # uso de CPU/memória em tempo real. Ctrl+C para sair
```

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

Você entra na "caixinha" (um mini-Linux só dela!). Experimente `ls`, `pwd`,
`cat main.py`. Para sair de dentro do contêiner, digite `exit`.

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
