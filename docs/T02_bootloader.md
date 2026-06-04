# T02 — Bootloader x86 (Sistemas Operacionais / IDP)

---

## 0. Contexto e objetivo

Escrever um **bootloader de 512 bytes** em assembly x86 (modo real, 16 bits, Intel 8086) que:
1. Prepara o ambiente (interrupções, segmentos, pilha).
2. Reseta o disco e **carrega um `kernel` externo** do segundo setor para a memória em `0x7E00`.
3. Coloca o **Verificador da Matrícula (VM)** no registrador `AX`.
4. Salta para o kernel, que imprime a **resposta final (string de uma única linha)** no QEMU.

**Entregáveis:** (a) a string resultante da execução correta; (b) o código do bootloader (`bootloader.s`).
**Prazo:** 07/06/2026 23:55 — entrega individual via Moodle.

---

## 1. Pré-requisitos

- Arquivo `kernel` (fornecido pelo professor) presente na pasta do projeto. **Confirme que ele existe antes de prosseguir.**
- Ferramentas com versões mínimas:
  - `gcc 13.3.0+` (usaremos `as` e `ld` do binutils)
  - `qemu-system-x86_64 8.2.2+`
  - `coreutils 9.4+` (para `dd`)
  - `gdb` (opcional, para debug)

**Ambiente:** Ubuntu 24.04.3 LTS rodando em WSL2 (PC Windows). Espelha o laboratório (gcc 13.3, qemu 8.2.2, coreutils 9.4, kernel 6.6.87-WSL2), então as versões devem bater sem ajustes.

**Instalação (Ubuntu 24.04 / WSL2):**
```bash
sudo apt update
sudo apt install -y build-essential qemu-system-x86 gdb python3 make
# coreutils (dd) já vem instalado
```
**Verificação das versões (rodar e me mostrar a saída):**
```bash
gcc --version; ld --version; qemu-system-x86_64 --version; dd --version | head -n1
```
> **QEMU no WSL2:** no Windows 11 (WSLg) o QEMU abre janela gráfica normalmente. Se nenhuma janela abrir, use modo texto no terminal: acrescente `-display curses` ao comando do QEMU (ex.: `qemu-system-x86_64 -display curses disco.img`). Para sair do modo curses: `Alt+2`, digite `quit`, Enter.

---

## 2. Estrutura do bootloader (`bootloader.s`)

Crie o arquivo `bootloader.s` com o conteúdo abaixo. A ordem das instruções segue a seção 4.3 do enunciado.

```asm
.code16                     # modo real (16 bits)
.intel_syntax noprefix
.global _start

_start:
    # 4.3.1 - desabilitar interrupcoes
    cli

    # 4.3.2 - limpar registradores de segmento (DS, ES, SS = 0x0)
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    # 4.3.3 - ponteiro de pilha para 0x7c00
    mov sp, 0x7c00

    # 4.3.4 - habilitar interrupcoes
    sti

    # 4.3.5 - resetar sistema de disco (int 0x13, funcao 0x0 -> AH=0)
    xor ax, ax              # AX = 0  => AH = 0 (reset)
    int 0x13

    # 4.3.6 - setar segmento estendido para 0x7E0
    # endereco = (segmento << 4) + offset => 0x7E0 << 4 = 0x7E00
    mov ax, 0x7E0
    mov es, ax
    xor bx, bx              # offset 0 => destino ES:BX = 0x7E0:0x0000 = fisico 0x7E00

    # 4.3.7 - carregar kernel (int 0x13, funcao 2 = Read Disk Sectors)
    mov ah, 0x02            # funcao de leitura
    mov al, 0x04            # numero de setores (kernel: 1500-2000 bytes)
    mov ch, 0x00            # cilindro 0
    mov cl, 0x02            # setor 2 (1-based; setor 1 = bootloader)
    mov dh, 0x00            # cabeca 0
    # DL preservado da BIOS (drive de boot) - nao tocamos em DL
    int 0x13

    # 4.3.8 - inserir o Verificador da Matricula (VM) em AX
    mov ax, 0x0000          # <<< SUBSTITUIR pelo VM calculado (ver secao 4) >>>

    # 4.3.9 - saltar para o kernel (0x7E00)
    jmp 0x7E00

end:
    # 4.1 - preencher com zeros ate o byte 510 e assinar com 0x55, 0xaa
    .fill 510 - (. - _start), 1, 0
    .byte 0x55, 0xaa        # assinatura -> 0xaa55 (little-endian) => total 512 bytes
```

**Notas de implementação (decisões já tomadas):**
- `DL` **não é alterado**: a BIOS entrega o número do drive de boot em `DL`, e como só mexemos em `DH` (cabeça), `DL` é preservado para o `int 0x13`. Se a leitura falhar no QEMU, *aí sim* tentar `mov dl, 0x80` antes do read.
- `ES:BX` é o buffer de destino da leitura: `ES=0x7E0`, `BX=0` → físico `0x7E00`.
- `jmp 0x7E00` é um salto near com `CS=0`, caindo no início do kernel.
- O `.fill 510 - (. - _start), 1, 0` garante exatos 512 bytes terminando na assinatura.

---

## 3. Build e teste do bootloader

```bash
# montar e linkar como binario plano carregado em 0x7c00
as -o bootloader.o bootloader.s
ld -o bootloader --oformat binary -Ttext 0x7c00 bootloader.o

# (opcional) inspecionar os 512 bytes e a assinatura no final
hexdump -C bootloader | tail -n 3
wc -c bootloader        # deve imprimir 512

# testar so o bootloader (tela preta + cursor = loop OK na etapa Hello World)
qemu-system-x86_64 bootloader
```

---

## 4. Cálculo do Verificador da Matrícula (VM)

Fórmula do enunciado (seção 4.3.8):

> VM = ( Σ_{i=1}^{n} (dᵢ · i)³ ) mod 4093

onde `dᵢ` é o i-ésimo dígito da matrícula (esquerda → direita) e `n` é a quantidade de dígitos.

> ⚠️ A tipografia do PDF é ambígua quanto a *onde* o cubo se aplica. O script abaixo calcula **as duas** interpretações; a **A** (cada termo ao cubo) é a leitura mais provável. Use a que o kernel aceitar ao validar.

```python
# calc_vm.py — substitua MATRICULA pelos dígitos da sua matrícula
MATRICULA = "SUA_MATRICULA_AQUI"   # somente digitos, ex: "12345678"

d = [int(c) for c in MATRICULA if c.isdigit()]
n = len(d)

# Interpretacao A: soma de (d_i * i)^3, depois mod 4093  (mais provavel)
vm_a = sum((d[i-1] * i) ** 3 for i in range(1, n + 1)) % 4093

# Interpretacao B: (soma de d_i * i)^3, depois mod 4093
vm_b = (sum(d[i-1] * i for i in range(1, n + 1)) ** 3) % 4093

print(f"n = {n}")
print(f"VM (A, cada termo ao cubo): {vm_a}  -> hex {hex(vm_a)}")
print(f"VM (B, soma ao cubo):       {vm_b}  -> hex {hex(vm_b)}")
```
```bash
python3 calc_vm.py
```
Depois, edite a linha `mov ax, 0x0000` no `bootloader.s` com o valor em hex (ex.: `mov ax, 0x0ABC`) e **rebuilde** (seção 3).

---

## 5. Montagem do disco e execução final

```bash
# 1) criar disco de 720KB zerado
dd if=/dev/zero of=disco.img bs=1024 count=720

# 2) copiar o bootloader para o setor 0 (sem truncar o disco)
dd if=bootloader of=disco.img conv=notrunc seek=0

# 3) copiar o kernel para o setor 2 (bs=512, seek=1 => offset 512 bytes)
dd if=kernel of=disco.img conv=notrunc bs=512 seek=1

# 4) executar
qemu-system-x86_64 disco.img
```
A execução correta exibe a **resposta da atividade** (string única) na tela do QEMU.

> ⚠️ **Cuidado com `dd`**: o parâmetro `of=` sobrescreve o caminho indicado. Confira os nomes/espaços antes de rodar.

---

## 6. Debug (validar localmente antes de submeter)

```bash
# terminal 1: QEMU pausado, com servidor GDB na porta 1234
qemu-system-x86_64 -s -S disco.img
```
```bash
# terminal 2
gdb
(gdb) target remote :1234
(gdb) break *0x7c00
(gdb) continue
```
Dica do enunciado: antes de cada `int`, coloque um breakpoint **logo após** a interrupção e dê `continue`, pois a interrupção "bagunça" a visualização das instruções no GDB (modo real).

---

## 7. Checklist de entrega

- [ ] `bootloader.s` monta sem erros e gera binário de **exatamente 512 bytes**.
- [ ] Assinatura `55 aa` nos 2 últimos bytes (conferir no `hexdump`).
- [ ] `VM` correto carregado em `AX` (validado contra o kernel).
- [ ] `disco.img` montado com bootloader (setor 0) + kernel (setor 2).
- [ ] QEMU imprime a **string de resposta**.
- [ ] Copiar a resposta **sem nenhuma quebra de linha** (string de uma única linha).
- [ ] Submeter no Moodle: **a string** + o **código do bootloader**.

### Sobre as verificações no Moodle
- A 1ª verificação é "grátis"; da **2ª em diante há penalização de 10% por verificação**.
- Por isso: valide tudo localmente (build de 512 bytes, assinatura, VM, execução no QEMU) e **só então** submeta. Tente acertar de primeira.
- Atenção máxima a **não incluir `\n` / espaços extras** ao colar a resposta.
