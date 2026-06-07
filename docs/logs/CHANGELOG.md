# Changelog — T02 Bootloader x86

Uma entrada por fase concluída (Conventional Commits + gitmoji).

## Fase 0 — Setup do repositório
- `chore: 🎉 estrutura inicial do repositório, README e Makefile`
- `Makefile` (build/check/boot/disk/run/debug + alvos `*-curses` para WSL sem WSLg).
- `README.md` (template T02 com Progresso); `.gitignore` (`*.o`, `bootloader`, `disco.img`).
- Ambiente confirmado: Ubuntu 24.04.3 LTS / WSL2 — gcc 13.3.0, qemu 8.2.2, dd 9.4, python3 3.12.3 (todos ≥ mínimos).
- `kernel` do Jere presente na raiz. Remoto: `origin → Felipebc2/Bootloader-Linux` (privado, reutilizado).

## Fase 1 — Hello World
- `feat: ✨ bootloader hello world (512 bytes + assinatura)`
- `bootloader.s` em modo real (`.code16`): `_start` em loop infinito, `.fill` ate 510 bytes e assinatura `0x55 0xaa`.
- `make check`: 512 bytes exatos, termina em `55 aa`.

## Fase 2 — Interrupção de vídeo
- `feat: ✨ impressão de caractere via int 0x10`
- `bootloader.s` imprime `A` (0x41) via teletype da BIOS (`int 0x10`, `AH=0x0E`, `BH=0x00`) e faz `hlt`.
- Fixada `.intel_syntax noprefix` (GNU `as` usa AT&T por padrao) para o codigo bater com a notacao da documentacao.
- `make check`: continua 512 bytes exatos, termina em `55 aa`.

## Fase 3 — Carregamento do kernel + salto
- `feat: ✨ carregamento do kernel e salto (seção 4.3)`
- Sequencia da secao 4.3: `cli` -> zera DS/ES/SS -> `sp=0x7c00` -> `sti` -> reset do disco (`int 0x13`, AH=0) -> `ES:BX=0x7E0:0` -> le 4 setores a partir do setor 2 (`int 0x13`, AH=2, AL=4, CH=0, CL=2, DH=0) -> `mov ax, 0x0000` (VM na Fase 4) -> `jmp 0x7E00`. `DL` nao e tocado.
- `jmp 0x7E00` montado como salto relativo (`e9 d6 01`); conferido via objdump que resolve para 0x7E00 com base de link 0x7c00.
- `make check`: 512 bytes exatos, termina em `55 aa`.

## Fase 4 — Verificador da Matrícula (VM)
- `feat: ➕ cálculo e inserção do verificador da matrícula (VM)`
- `scripts/calc_vm.py` calcula `VM_A` (eq. 1 oficial) e `VM_B` (alternativa) a partir da matricula, imprimindo decimal e hex.
- Matricula `2311292` -> `VM_A = 1896 = 0x0768` (inserido em AX) e `VM_B = 2129 = 0x0851` (guardado).
- `bootloader.s`: `mov ax, 0x0000` -> `mov ax, 0x0768`.
- `make check`: 512 bytes exatos, termina em `55 aa`.
