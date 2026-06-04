# T02 — Orquestrador de Execução (Bootloader x86 · IDP · Sistemas Operacionais)

---

## 🧭 PROTOCOLO DO ORQUESTRADOR (ler primeiro)

1. Trabalhe **uma fase por vez**, na ordem da tabela abaixo.
2. Ao final de **cada** fase, obrigatoriamente:
   - rodar os **critérios de aceite** da fase;
   - **atualizar o `README.md`** (seção *Progresso* + changelog);
   - fazer **commit** (Conventional Commits + gitmoji);
   - **PARAR** e apresentar um resumo curto: o que foi feito, saída dos checks, e o que preciso revisar.
3. **Nunca** pule um gate de revisão. **Nunca** rode `git push` sem minha confirmação.
4. Se um check falhar, **pare e reporte** — não tente "consertar" silenciosamente.
5. Antes de qualquer `dd`, **mostre o comando** e confira nomes/espaços (o `of=` sobrescreve o destino).

### Tabela de fases
| # | Fase | Entregável | Gate |
|---|------|-----------|------|
| 0 | Setup: repo + README + tooling | repositório, `README.md`, versões confirmadas | 🛑 revisão |
| 1 | Bootloader "Hello World" (512 B + assinatura) | `bootloader.s` montando em 512 B | 🛑 revisão |
| 2 | Interrupção de vídeo (`int 0x10`) | impressão de caractere testada | 🛑 revisão |
| 3 | Bootloader completo (carregar kernel + salto) | `bootloader.s` final (seção 4.3) | 🛑 revisão |
| 4 | Verificador da Matrícula (VM) | `VM` em `AX`, validado | 🛑 revisão |
| 5 | Montagem do disco + execução | `disco.img`, resposta no QEMU | 🛑 revisão |
| 6 | Validação/debug + captura da resposta | `RESPOSTA.txt` (linha única) | 🛑 revisão |
| 7 | Empacotamento final p/ entrega | README final, push opcional | 🛑 revisão |

---

## 🧩 SKILLS / FERRAMENTAS NECESSÁRIAS

O orquestrador precisa das seguintes capacidades. Confirme disponibilidade na **Fase 0**.

- **Bash / shell**: `as`, `ld` (binutils), `qemu-system-x86_64`, `dd`, `hexdump`, `wc`, `gdb`.
- **Edição de arquivos**: criar/editar `bootloader.s`, `Makefile`, `README.md`, scripts.
- **Python 3**: rodar `scripts/calc_vm.py`.
- **Git + GitHub CLI (`gh`)**: inicializar repo, commits, criar repo remoto **privado**.

**Versões mínimas exigidas pelo enunciado:** `gcc 13.3.0+`, `qemu-system-x86_64 8.2.2+`, `coreutils 9.4+`.

**Ambiente: Ubuntu 24.04.3 LTS em WSL2** (espelha o laboratório — versões devem bater sem ajustes).

**Instalação (Ubuntu 24.04 / WSL2):**
```bash
sudo apt update
sudo apt install -y build-essential qemu-system-x86 gdb python3 make
# coreutils (dd) já vem instalado
# GitHub CLI:
sudo apt install -y gh   # se indisponível: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
gh auth login            # autenticar antes de criar o repo remoto
```

> **QEMU no WSL2:** no Windows 11 (WSLg) o QEMU abre janela gráfica. Se nenhuma janela abrir, use modo texto: acrescente `-display curses` ao comando (alvos `boot-curses`/`run-curses` no Makefile). Sair do curses: `Alt+2`, `quit`, Enter.

**Permissões sugeridas (`.claude/settings.json`)** — para o orquestrador rodar sem pedir confirmação a cada comando seguro, mas **bloqueando ações destrutivas**:
```json
{
  "permissions": {
    "allow": [
      "Bash(as:*)", "Bash(ld:*)", "Bash(make:*)",
      "Bash(qemu-system-x86_64:*)", "Bash(hexdump:*)",
      "Bash(wc:*)", "Bash(python3 scripts/calc_vm.py:*)",
      "Bash(git add:*)", "Bash(git commit:*)", "Bash(git status:*)"
    ],
    "deny": [
      "Bash(git push:*)",
      "Bash(rm -rf:*)",
      "Bash(dd of=/dev/*)"
    ]
  }
}
```
> `git push` e `dd` em `/dev/*` ficam bloqueados de propósito: push só com minha aprovação, e `dd` só pode escrever em `disco.img`.

---

## 📁 ESTRUTURA DO REPOSITÓRIO (criar na Fase 0)

```
so-t02-bootloader/
├── README.md            # atualizado ao fim de CADA fase
├── Makefile             # build/run/debug padronizados (evita erro manual de dd)
├── bootloader.s         # código-fonte do bootloader
├── kernel               # fornecido pelo professor (colocar manualmente)
├── scripts/
│   └── calc_vm.py       # cálculo do Verificador da Matrícula
├── RESPOSTA.txt         # string final (linha única, SEM \n no fim)
├── .gitignore
└── docs/
    └── enunciado.pdf    # opcional
```

**`.gitignore`:**
```
*.o
bootloader
disco.img
```

**`Makefile`:**
```makefile
ASM    = bootloader.s
BIN    = bootloader
DISK   = disco.img
KERNEL = kernel

$(BIN): $(ASM)
	as -o bootloader.o $(ASM)
	ld -o $(BIN) --oformat binary -Ttext 0x7c00 bootloader.o

check: $(BIN)
	@echo "Tamanho (deve ser 512):" && wc -c $(BIN)
	@echo "Ultimos bytes (deve terminar 55 aa):" && hexdump -C $(BIN) | tail -n 2

boot: $(BIN)
	qemu-system-x86_64 $(BIN)

boot-curses: $(BIN)
	qemu-system-x86_64 -display curses $(BIN)

disk: $(BIN) $(KERNEL)
	dd if=/dev/zero of=$(DISK) bs=1024 count=720
	dd if=$(BIN) of=$(DISK) conv=notrunc seek=0
	dd if=$(KERNEL) of=$(DISK) conv=notrunc bs=512 seek=1

run: disk
	qemu-system-x86_64 $(DISK)

run-curses: disk
	qemu-system-x86_64 -display curses $(DISK)

debug: disk
	qemu-system-x86_64 -s -S $(DISK)

clean:
	rm -f bootloader.o $(BIN) $(DISK)

.PHONY: check boot boot-curses disk run run-curses debug clean
```
> WSLg ausente? Use `make boot-curses` / `make run-curses` (modo texto no terminal).

**Template do `README.md`** (preencher e manter atualizado):
```markdown
# T02 — Bootloader x86 (Sistemas Operacionais · IDP)

Bootloader de 512 bytes em modo real que carrega um kernel para `0x7E00`,
insere o Verificador da Matrícula em `AX` e salta para o kernel.

- **Disciplina:** Sistemas Operacionais — Prof. Jeremias Moreira Gomes — 2026/1
- **Aluno:** Felipe
- **Ambiente:** Ubuntu 24.04.3 LTS (WSL2) — gcc / binutils / qemu / coreutils

## Como executar
\`\`\`bash
make check   # confere 512 bytes + assinatura 55 aa
make boot    # testa so o bootloader (sem WSLg: make boot-curses)
make run     # monta disco.img (bootloader + kernel) e roda (sem WSLg: make run-curses)
make debug   # QEMU pausado + servidor GDB :1234
\`\`\`

## Progresso
- [ ] Fase 0 — Setup do repositório
- [ ] Fase 1 — Hello World (512 B + assinatura)
- [ ] Fase 2 — Interrupção de vídeo
- [ ] Fase 3 — Carregamento do kernel + salto
- [ ] Fase 4 — Verificador da Matrícula (VM)
- [ ] Fase 5 — Montagem do disco + execução
- [ ] Fase 6 — Validação + resposta capturada
- [ ] Fase 7 — Entrega

## Changelog
- _(o orquestrador adiciona uma linha por fase concluída)_
```

> **Regra de atualização do README:** ao concluir cada fase, marcar o item correspondente em *Progresso* com `[x]` e adicionar uma linha no *Changelog* descrevendo a entrega.

---

## 🚦 FASES

### FASE 0 — Setup: repositório + README + tooling
**Ações:**
```bash
mkdir -p so-t02-bootloader/scripts so-t02-bootloader/docs && cd so-t02-bootloader
git init
# criar .gitignore, Makefile, README.md (templates acima)
# confirmar versoes:
gcc --version; ld --version; qemu-system-x86_64 --version; dd --version | head -n1; python3 --version
```
Criar o repositório remoto **privado** (NÃO dar push ainda):
```bash
gh repo create Felipebc2/so-t02-bootloader --private --source=. --remote=origin
```
**Critério de aceite:** estrutura de pastas criada; versões atendem aos mínimos; `README.md` e `Makefile` presentes.
**README:** marcar Fase 0; changelog `chore: estrutura inicial`.
**Commit:** `chore: 🎉 estrutura inicial do repositório, README e Makefile`
🛑 **GATE:** apresentar as versões detectadas e a árvore de arquivos. Aguardar minha aprovação.

---

### FASE 1 — Bootloader "Hello World" (512 B + assinatura)
**Objetivo:** `bootloader.s` mínimo (loop infinito) com exatos 512 bytes terminando em `55 aa`.
```asm
.code16
.intel_syntax noprefix
.global _start
_start:
    jmp _start
end:
    .fill 510 - (. - _start), 1, 0
    .byte 0x55, 0xaa
```
```bash
make check    # wc -c deve dar 512; hexdump deve terminar em 55 aa
make boot     # tela preta + cursor piscando = OK (sem WSLg: make boot-curses)
```
**Critério de aceite:** binário com 512 bytes; últimos bytes `55 aa`; QEMU mostra "Booting from Hard Disk..." e cursor.
**README:** marcar Fase 1; changelog.
**Commit:** `feat: ✨ bootloader hello world (512 bytes + assinatura)`
🛑 **GATE:** colar saída de `make check`. Aguardar aprovação.

---

### FASE 2 — Interrupção de vídeo (`int 0x10`)
**Objetivo:** validar o mecanismo de interrupção imprimindo um caractere antes do `hlt`.
```asm
.code16
.intel_syntax noprefix
.global _start
_start:
    mov al, 0x41      # 'A'
    mov ah, 0x0E      # teletype
    mov bh, 0x00      # pagina 0
    int 0x10
    hlt
end:
    .fill 510 - (. - _start), 1, 0
    .byte 0x55, 0xaa
```
```bash
make check && make boot   # deve aparecer 'A' (sem WSLg: make boot-curses)
```
**Critério de aceite:** caractere `A` impresso no QEMU; ainda 512 bytes.
**README:** marcar Fase 2; changelog.
**Commit:** `feat: ✨ impressão de caractere via int 0x10`
🛑 **GATE:** confirmar que apareceu `A`. Aguardar aprovação.

---

### FASE 3 — Bootloader completo (carregar kernel + salto)
**Objetivo:** implementar a seção 4.3 do enunciado, na ordem exata. Substituir o `bootloader.s` por:
```asm
.code16
.intel_syntax noprefix
.global _start

_start:
    cli                     # 4.3.1 desabilitar interrupcoes

    xor ax, ax              # 4.3.2 limpar DS, ES, SS
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, 0x7c00          # 4.3.3 ponteiro de pilha

    sti                     # 4.3.4 habilitar interrupcoes

    xor ax, ax              # 4.3.5 resetar disco (int 0x13, AH=0)
    int 0x13

    mov ax, 0x7E0           # 4.3.6 segmento estendido (0x7E0<<4 = 0x7E00)
    mov es, ax
    xor bx, bx              # offset 0 => ES:BX = fisico 0x7E00

    mov ah, 0x02            # 4.3.7 ler disco
    mov al, 0x04            # 4 setores
    mov ch, 0x00            # cilindro 0
    mov cl, 0x02            # setor 2
    mov dh, 0x00            # cabeca 0
    int 0x13                # DL preservado da BIOS (drive de boot)

    mov ax, 0x0000          # 4.3.8 VM em AX  <<< preenchido na FASE 4 >>>

    jmp 0x7E00              # 4.3.9 salto para o kernel

end:
    .fill 510 - (. - _start), 1, 0
    .byte 0x55, 0xaa
```
**Decisões fechadas:**
- `DL` **não é alterado** (preservado da BIOS). Se a leitura falhar no QEMU, *única* alteração a testar: `mov dl, 0x80` antes do `int 0x13`.
- `ES:BX = 0x7E0:0x0000` → destino físico `0x7E00`.
```bash
make check   # ainda 512 bytes + 55 aa
```
**Critério de aceite:** monta sem erro; 512 bytes; assinatura ok. (Resposta ainda será `0000` no AX até a Fase 4.)
**README:** marcar Fase 3; changelog.
**Commit:** `feat: ✨ carregamento do kernel e salto (seção 4.3)`
🛑 **GATE:** colar `make check`. Aguardar aprovação.

---

### FASE 4 — Verificador da Matrícula (VM)
**Objetivo:** calcular o VM e inseri-lo em `AX`.
Criar `scripts/calc_vm.py`:
```python
MATRICULA = "SUA_MATRICULA_AQUI"   # PEDIR ao Felipe; somente digitos
d = [int(c) for c in MATRICULA if c.isdigit()]
n = len(d)
# Fórmula: VM = ( Σ_{i=1}^{n} (d_i * i)^3 ) mod 4093
vm_a = sum((d[i-1] * i) ** 3 for i in range(1, n + 1)) % 4093          # interpretacao A (provavel)
vm_b = (sum(d[i-1] * i for i in range(1, n + 1)) ** 3) % 4093          # interpretacao B (alternativa)
print(f"n={n}  | VM_A={vm_a} ({hex(vm_a)})  | VM_B={vm_b} ({hex(vm_b)})")
```
> ⚠️ **PARAR e me pedir a matrícula** antes de rodar. Não inventar dígitos.
```bash
python3 scripts/calc_vm.py
```
Editar `bootloader.s`: `mov ax, 0x0000` → `mov ax, <hex do VM_A>`. Depois `make check`.
**Critério de aceite:** script roda; `AX` atualizado com o VM (usar interpretação **A**; guardar B como alternativa); 512 bytes.
**README:** marcar Fase 4; changelog.
**Commit:** `feat: ➕ cálculo e inserção do verificador da matrícula (VM)`
🛑 **GATE:** mostrar VM_A e VM_B e a linha alterada do `bootloader.s`. Aguardar aprovação.

---

### FASE 5 — Montagem do disco + execução
**Objetivo:** montar `disco.img` (bootloader no setor 0, kernel no setor 2) e rodar.
> ⚠️ Confirmar que o arquivo `kernel` está na pasta antes de prosseguir.
```bash
make run    # roda: cria disco.img -> copia bootloader -> copia kernel -> qemu
```
**Critério de aceite:** QEMU exibe a **string de resposta** da atividade.
**README:** marcar Fase 5; changelog.
**Commit:** `build: 📦 montagem do disco e execução no QEMU`
🛑 **GATE:** descrever exatamente o que apareceu na tela do QEMU. Aguardar aprovação.

---

### FASE 6 — Validação + captura da resposta
**Objetivo:** confirmar a resposta e salvá-la **em uma única linha, sem `\n` final**.
- Se a saída parecer incorreta, depurar com `make debug` (GDB em `:1234`, `break *0x7c00`, `continue`; colocar breakpoint **após** cada `int`).
- Salvar a resposta exatamente (substituir `RESPOSTA`):
```bash
printf '%s' 'RESPOSTA' > RESPOSTA.txt   # printf evita quebra de linha no final
wc -c RESPOSTA.txt && hexdump -C RESPOSTA.txt | tail -n 2   # conferir que NAO termina em 0a
```
**Critério de aceite:** `RESPOSTA.txt` sem `0a` no final; conteúdo confere com a tela do QEMU.
**README:** marcar Fase 6; changelog.
**Commit:** `docs: 📝 captura da resposta final`
🛑 **GATE:** colar o `hexdump` do `RESPOSTA.txt` para eu confirmar ausência de quebra de linha. Aguardar aprovação.

---

### FASE 7 — Empacotamento final para entrega
**Objetivo:** deixar tudo pronto para o Moodle.
- Conferir checklist final (abaixo) e finalizar o README.
- **Só com minha aprovação explícita**, dar push:
```bash
git push -u origin main
```
**Lembrete de entrega no Moodle:** submeter **a string** (`RESPOSTA.txt`) + o **código do bootloader** (`bootloader.s`). Prazo **07/06/2026 23:55**.
**Commit:** `docs: 🚀 finalização e instruções de entrega`
🛑 **GATE FINAL.**

---

## ✅ CHECKLIST FINAL (Fase 7)
- [ ] `bootloader.s` monta sem erros e gera **exatamente 512 bytes**.
- [ ] Últimos 2 bytes = `55 aa`.
- [ ] `VM` correto em `AX` (interpretação validada contra o kernel).
- [ ] `disco.img` = bootloader (setor 0) + kernel (setor 2).
- [ ] QEMU imprime a string de resposta.
- [ ] `RESPOSTA.txt` em **linha única, sem `\n` final**.
- [ ] README com Progresso 100% e changelog completo.

## ⚠️ Sobre as verificações no Moodle
- 1ª verificação é livre; **da 2ª em diante há penalização de 10% por verificação**.
- Validar **tudo localmente** (512 B, assinatura, VM, execução, ausência de `\n`) antes de submeter. Mirar em acertar de primeira.
