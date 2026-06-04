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
