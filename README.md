# T02 — Bootloader x86 (Sistemas Operacionais · IDP)

Bootloader de 512 bytes em modo real que carrega um kernel para `0x7E00`,
insere o Verificador da Matrícula em `AX` e salta para o kernel.

- **Disciplina:** Sistemas Operacionais
- **Ambiente:** Ubuntu 24.04.3 LTS (WSL2) — gcc / binutils / qemu / coreutils

## Como executar
```bash
make check   # confere 512 bytes + assinatura 55 aa
make boot    # testa so o bootloader (sem WSLg: make boot-curses)
make run     # monta disco.img (bootloader + kernel) e roda (sem WSLg: make run-curses)
make debug   # QEMU pausado + servidor GDB :1234
```

## Progresso
- [x] Fase 0 — Setup do repositório
- [ ] Fase 1 — Hello World (512 B + assinatura)
- [ ] Fase 2 — Interrupção de vídeo
- [ ] Fase 3 — Carregamento do kernel + salto
- [ ] Fase 4 — Verificador da Matrícula (VM)
- [ ] Fase 5 — Montagem do disco + execução
- [ ] Fase 6 — Validação + resposta capturada
- [ ] Fase 7 — Entrega

## Changelog
O histórico por fase fica em [`docs/logs/CHANGELOG.md`](docs/logs/CHANGELOG.md).

## Documentação
- [`docs/ORQUESTRACAO.md`](docs/ORQUESTRACAO.md) — plano operacional por fases.
- [`CLAUDE.md`](CLAUDE.md) — regras e decisões do projeto.
- `docs/T02_Requisitos.md` · `docs/T02_orquestrador.md` · `docs/T02_bootloader.md` — fontes.
