# Parte 1 — Primeiros passos com SSH

## O que é SSH?

**SSH** (*Secure Shell*) é uma forma de **controlar outro computador pelo terminal**,
de forma segura, pela internet. Em vez de mexer no seu próprio PC, você vai dar
comandos em um **servidor** lá na nuvem (na Alemanha, no nosso caso!).

Tudo o que você digitar acontece **no servidor**, não no seu computador.

> 💡 Pense no SSH como um "controle remoto" do servidor, só que por texto.

---

## O que o professor vai te entregar

1. O **IP** do servidor do seu grupo (ex: `167.233.61.233`).
2. A **senha** do grupo (ex: `grupo1`).

O comando de acesso é assim:

```
ssh -p 53 root@SEU_IP
```

Entendendo cada pedaço do comando:

| Pedaço | Significado |
|---|---|
| `ssh` | o programa que conecta |
| `-p 53` | conecta na **porta 53** (a porta normal do SSH é a 22, mas a rede do IFSP bloqueia ela; a 53 funciona) |
| `root` | o nome do usuário no servidor (o "administrador") |
| `SEU_IP` | o endereço do servidor (ex: `167.233.61.233`) |

---

## Passo 1 — Abrir o PowerShell (Windows)

- Clique no menu **Iniciar** e digite **PowerShell**.
- Clique em **Windows PowerShell** para abrir.

> O Windows já vem com o SSH instalado dentro do PowerShell — não precisa baixar nada.
>
> No **Mac/Linux** é o mesmo: abra o **Terminal** e os comandos são idênticos.

## Passo 2 — Conectar no servidor

Digite (trocando `SEU_IP` pelo IP do seu grupo):

```
ssh -p 53 root@SEU_IP
```

Na **primeira vez** vai aparecer uma pergunta como:

```
The authenticity of host ... can't be established.
Are you sure you want to continue connecting (yes/no)?
```

Digite `yes` e tecle Enter. (Isso só acontece na primeira conexão.)

Em seguida ele vai pedir a **senha**:

```
root@SEU_IP's password:
```

Digite a senha do grupo (ex: `grupo1`) e tecle Enter.

> ⚠️ **A senha NÃO aparece enquanto você digita** (nem aparecem bolinhas).
> Isso é normal e é por segurança! Digite com calma e aperte Enter.

Se deu tudo certo, seu terminal vai mudar para algo como:

```
root@aula-grupo1:~#
```

🎉 **Você está dentro do servidor!** Daqui pra frente, tudo o que você digitar
roda lá na nuvem.

---

## Passo 3 — Exercícios de comandos básicos

Faça um de cada vez e observe o resultado. **Anote** ou tire print do que cada um faz.

### Onde estou e quem sou eu

```
whoami        # mostra seu usuário (vai aparecer "root")
hostname      # nome do servidor
pwd           # mostra a pasta onde você está agora (Print Working Directory)
```

### Olhando arquivos e pastas

```
ls            # lista o que tem na pasta atual
ls -la        # lista TUDO (até arquivos ocultos) com detalhes
```

### Andando entre pastas

```
cd /          # vai para a raiz do sistema
ls            # veja as pastas do sistema Linux
cd ~          # volta para a sua pasta pessoal (home). O ~ significa "minha casa"
pwd           # confirme onde você está
```

### Criando pastas e arquivos

```
mkdir teste           # cria uma pasta chamada "teste"
cd teste              # entra nela
touch ola.txt         # cria um arquivo vazio chamado ola.txt
ls                    # confirme que o arquivo está lá
```

### Escrevendo dentro de um arquivo (editor nano)

```
nano ola.txt
```

- Digite uma frase qualquer.
- Para **salvar**: `Ctrl + O` e depois `Enter`.
- Para **sair** do nano: `Ctrl + X`.

Agora veja o conteúdo do arquivo sem abrir o editor:

```
cat ola.txt
```

### Apagando

```
rm ola.txt        # apaga o arquivo
cd ~              # volta pra home
rm -r teste       # apaga a pasta "teste" e tudo dentro dela (-r = recursivo)
```

> ⚠️ **Cuidado com o `rm`!** No Linux não tem "lixeira": o que você apaga,
> some de verdade. Sempre confira o que está apagando.

### Conhecendo o servidor

```
uname -a      # informações do sistema operacional
df -h         # espaço em disco (-h = "human", em GB/MB)
free -h       # memória RAM
nproc         # quantos núcleos de processador o servidor tem
```

### Limpar e sair

```
clear         # limpa a tela do terminal
exit          # SAI do servidor (encerra a conexão SSH)
```

Depois de sair com `exit`, conecte de novo (Passo 2) para praticar.

---

## Passo 4 — (Aprendizado) Gerando uma chave SSH

Hoje vamos entrar com **senha** porque é mais simples. Mas, no mundo real, o jeito
mais usado e mais seguro de acessar servidores é com uma **chave SSH** — um par de
arquivos (uma parte *pública* e uma parte *privada*) que substitui a senha.

Vamos só **conhecer** como ela é criada. **No seu PowerShell** (sem estar conectado
no servidor — se estiver, dê `exit` antes), digite:

```
ssh-keygen -t ed25519
```

- Quando perguntar o local do arquivo, só aperte **Enter** (usa o padrão).
- Quando pedir uma *passphrase*, pode apertar **Enter** duas vezes (sem senha).

Ele vai criar dois arquivos. Veja a parte **pública** da sua chave:

```
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

Aquele texto começando com `ssh-ed25519 ...` é a sua **chave pública** — é ela que
você colocaria no servidor para entrar sem digitar senha.

> 💬 **Resumo:** chave SSH é o método mais usado em produção (mais seguro que senha).
> Hoje, para facilitar, vamos usar senha — mas agora você já sabe que a chave existe
> e como ela é gerada.

---

## ✅ Checklist da Parte 1

- [ ] Consegui conectar no servidor com `ssh -p 53 root@IP` e a senha do grupo
- [ ] Entendi que a senha não aparece enquanto digito
- [ ] Sei descobrir em que pasta estou (`pwd`) e listar arquivos (`ls -la`)
- [ ] Criei uma pasta, entrei nela e criei um arquivo
- [ ] Editei um arquivo com o `nano` e li com o `cat`
- [ ] Apaguei arquivo/pasta com `rm`
- [ ] Gerei uma chave SSH com `ssh-keygen` e vi a parte pública dela
- [ ] Saí com `exit` e consegui reconectar

Quando todos estiverem marcados, chame o professor e siga para a **Parte 2**.
