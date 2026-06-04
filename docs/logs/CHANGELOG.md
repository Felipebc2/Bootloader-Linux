# Changelog — T02 Bootloader x86

Uma entrada por fase concluída (Conventional Commits + gitmoji).

## Fase 0 — Setup do repositório
- `chore: 🎉 estrutura inicial do repositório, README e Makefile`
- `Makefile` (build/check/boot/disk/run/debug + alvos `*-curses` para WSL sem WSLg).
- `README.md` (template T02 com Progresso); `.gitignore` (`*.o`, `bootloader`, `disco.img`).
- Ambiente confirmado: Ubuntu 24.04.3 LTS / WSL2 — gcc 13.3.0, qemu 8.2.2, dd 9.4, python3 3.12.3 (todos ≥ mínimos).
- `kernel` do Jere presente na raiz. Remoto: `origin → Felipebc2/Bootloader-Linux` (privado, reutilizado).
