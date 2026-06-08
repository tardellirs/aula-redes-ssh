# Plano da Aula — SSH, Flask e Contêineres na nuvem

Guia do **professor**. Os alunos recebem os arquivos `PARTE-1`, `PARTE-2` e `PARTE-3`.

## Objetivo

Pegar o **jogo da cobrinha em Flask** que os alunos já fizeram e colocá-lo **no ar**
em um servidor real na nuvem (Hetzner), aprendendo no caminho:

1. **SSH** — acessar e operar um servidor remoto pelo terminal (eles nunca usaram).
2. **Deploy direto** — rodar com `python3 main.py` e descobrir que o site cai ao
   desconectar.
3. **Contêineres (Docker)** — deixar o site no ar de verdade, sozinho.

Os alunos usam **Windows com PowerShell** (o SSH já vem incluso, não precisa instalar
nada). Acesso por **senha** (mais simples). O site é acessado por `http://IP`.

## Tempo estimado

| Parte | Conteúdo | Tempo |
|---|---|---|
| Intro | O que é servidor/nuvem/SSH | 10 min |
| Parte 1 | SSH: conectar + comandos básicos + gerar chave | 30–40 min |
| Parte 2 | Deploy direto (5000 → 80) e o problema | 30 min |
| Parte 3 | Docker: site no ar + comandos | 30–40 min |

Cabe em uma aula de ~2h ou em duas aulas (1: SSH; 2: deploy + contêiner).

---

## ✅ Status: testado de ponta a ponta

Todo o fluxo foi validado em uma instância CX23 real (08/06/2026):

- Criação CX23 + SSH na porta 53 (porta 22 também ativa) ✔
- Login por **chave** e por **senha** na porta 53 ✔
- `git clone` do projeto (do GitHub) no servidor ✔
- Flask na **porta 5000** e na **porta 80** acessível externamente ✔
- Nomes do grupo renderizados pelo Flask ✔
- `docker build` + `docker run -d -p 80:5000 --restart unless-stopped` ✔
- Site **continua no ar após fechar o SSH** ✔
- Site **volta sozinho após reiniciar o servidor** ✔

---

## Preparação ANTES da aula

### 1. Provisionar um servidor por grupo

A env da Hetzner está em `/Users/tardelli/Workplace/hackathon-servers/.env`
(o script lê de lá automaticamente). Para cada grupo:

```bash
cd /Users/tardelli/Workplace/Classes/redes-flask-hetzner
./provisionar-aula.sh grupo1
./provisionar-aula.sh grupo2
./provisionar-aula.sh grupo3
# ... um por grupo
```

Cada execução:
- cria a instância (tenta **CX23 → CX33 → CPX22**, a mais barata disponível);
- habilita SSH na **porta 53** e **login por senha** (senha = nome do grupo, ex: `grupo1`);
- instala Docker e pip;
- libera a porta 80.

Ao final, o script mostra o **IP** e a **senha** de cada grupo. A senha de cada grupo
também fica salva em `keys/senhas.csv` (fora do GitHub).

A qualquer momento, veja **todos os servidores de uma vez** (grupo, IP, tipo, status,
se o site está no ar e a senha):

```bash
./listar-aulas.sh
```

> **Os nomes dos grupos são definidos por você** ao provisionar (ex: `grupo1`,
> `grupo2`, ...). Os times escolhem o nome real deles, mas no servidor padronizamos
> como `grupoN` para a senha ficar simples. O `listar-aulas.sh` mostra o que existe.

### 2. Distribuir para cada grupo

Basta entregar:

- O **IP** do servidor e a **senha** (ex: `grupo1`).

Toda a aula está publicada no seu GitHub e os alunos clonam direto no servidor com
`git clone` (sem precisar transferir arquivos). A cobrinha fica na pasta `app/`:

> **Repositório:** https://github.com/tardellirs/aula-redes-ssh (público)
>
> No servidor: `git clone https://github.com/tardellirs/aula-redes-ssh.git` e depois
> `cd aula-redes-ssh/app`.

Se quiser mudar o conteúdo (ex: corrigir algo), edite os arquivos deste diretório e
dê `git push` — ele já está conectado ao repositório.

### 3. ⚠️ Confirmar as portas na rede do IFSP

Sabemos que o IFSP **bloqueia a porta 22** e **libera a 53** (por isso o SSH usa 53).
O mesmo firewall pode bloquear a **porta 5000**.

- **Teste antes da aula, na rede do IFSP**, se `http://IP:5000` abre. (Use o servidor
  de teste ou um dos grupos.)
- Se a 5000 estiver bloqueada, sem problema: a **Parte 2 já orienta os alunos a
  pular direto para a porta 80**, que é http padrão e quase certamente passa.

---

## Custos e limpeza

- CX23 ≈ **€4,99/mês**, cobrado **proporcional ao tempo ligado** (algumas horas de
  aula custam centavos).
- **Apague os servidores depois da aula:**

```bash
./apagar-aula.sh grupo1
./apagar-aula.sh grupo2
# ...
```

Isso remove a instância, a chave SSH na Hetzner e a chave local.

---

## Pontos-chave de cada parte (para conduzir)

**Parte 1 — SSH**
- Reforce: tudo que digitam roda **no servidor**, não no PC deles.
- A **senha não aparece** ao digitar — é a dúvida nº 1 dos iniciantes.
- Porta 53 em vez de 22: boa deixa para falar de **portas e firewall**.
- O `ssh-keygen` é só para conhecerem; o login do dia é por senha.

**Parte 2 — Deploy direto**
- O "aha" da porta 80: `http://IP` sem `:porta` → porque 80 é o padrão da web.
- O **problema** (site cai ao fechar o SSH) é o gancho para a Parte 3. Não conserte
  ainda — deixe-os sentirem o problema.

**Parte 3 — Contêiner**
- O "aha": fecharam o SSH e o site **continuou no ar**.
- `-p 80:5000` é o conceito de **mapeamento de portas** (fora 80 ↔ dentro 5000).
- `docker exec -it cobrinha sh` impressiona: o contêiner tem seu próprio ambiente Linux isolado.

---

## Solução de problemas

| Sintoma | Causa / solução |
|---|---|
| "A senha não digita nada" | Normal — senha é oculta. Digite e dê Enter. |
| `git clone` falha / pede senha do GitHub | Confirme a URL e que o repositório está **público**. Sendo público, não pede login. |
| `http://IP:5000` não abre no IFSP | Firewall do IFSP pode bloquear a 5000. Pular para a porta 80 (Parte 2, Passo 6). |
| `pip install flask` dá erro (`externally-managed`) | No servidor usamos `apt install -y python3-flask` (já está no handout). |
| `docker run` diz que a **porta 80 está em uso** | Sobrou o Flask da Parte 2 rodando. Rode `pkill -f main.py` e tente de novo. |
| Aluno fechou o terminal e "perdeu tudo" | Os arquivos continuam no servidor. É só reconectar com `ssh -p 53 root@IP`. |
| Esqueceu a senha do grupo | É o nome do grupo (ex: `grupo1`). Ou veja na saída do `provisionar-aula.sh`. |

---

## Arquivos deste projeto

```
aula-redes-ssh/              # repositório da aula (github.com/tardellirs/aula-redes-ssh)
├── app/                     # a cobrinha (os alunos clonam o repo e entram aqui)
│   ├── main.py              # Flask + lista "integrantes" (nomes do grupo)
│   ├── templates/index.html # jogo da cobrinha
│   ├── Dockerfile           # receita do contêiner (Parte 3)
│   └── requirements.txt
├── provisionar-aula.sh      # cria 1 servidor por grupo (CX23, porta 53, senha, Docker)
├── listar-aulas.sh          # lista grupos, IPs, status, site no ar e senhas
├── apagar-aula.sh           # apaga o servidor de um grupo
├── PARTE-1-ssh.md           # handout do aluno
├── PARTE-2-flask.md         # handout do aluno
├── PARTE-3-conteiner.md     # handout do aluno
├── PLANO-DA-AULA.md         # este guia
└── keys/                    # chaves SSH do professor (NÃO vai pro GitHub — .gitignore)
```
