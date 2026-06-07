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
- [x] Fase 1 — Hello World (512 B + assinatura)
- [x] Fase 2 — Interrupção de vídeo (imprime `A`)
- [x] Fase 3 — Carregamento do kernel + salto
- [x] Fase 4 — Verificador da Matrícula (VM)
- [x] Fase 5 — Montagem do disco + execução
- [x] Fase 6 — Validação + resposta capturada
- [x] Fase 7 — Entrega

## Changelog
O histórico por fase fica em [`docs/logs/CHANGELOG.md`](docs/logs/CHANGELOG.md).

## Documentação
- `docs/T02_Requisitos.md` · `docs/T02_bootloader.md` — enunciado e material de apoio.

## O que foi feito
- **`bootloader.s`** — um setor de boot de **512 bytes** em assembly x86 (modo real,
  16 bits), terminado pela assinatura MBR `0x55 0xaa`.
- Impressão de caractere via serviço de vídeo da BIOS (`int 0x10`).
- Carregamento do **kernel** (a partir do 2º setor do disco) para o endereço
  `0x7E00` usando o serviço de disco da BIOS (`int 0x13`).
- Cálculo e inserção do **Verificador da Matrícula (VM)** no registrador `AX`.
- **`scripts/calc_vm.py`** — calcula o VM a partir da matrícula.
- **`Makefile`** — alvos para montar, verificar (`check`), executar no QEMU
  (`boot`/`run`) e depurar (`debug`).
- **`RESPOSTA.txt`** — a string de resposta final impressa pelo kernel.

## Como funciona
1. A BIOS carrega o 1º setor do disco (o bootloader) para `0x7c00` e executa a
   partir dali, em modo real (16 bits).
2. O bootloader prepara o ambiente: desabilita interrupções, zera os segmentos
   (`DS`/`ES`/`SS`), aponta a pilha para `0x7c00` e reabilita interrupções.
3. Reseta o disco e lê os setores do kernel (`int 0x13`) para `ES:BX = 0x7E0:0`,
   ou seja, o endereço físico `0x7E00`. O drive de boot (`DL`) é preservado.
4. Coloca o **VM** no registrador `AX` e salta (`jmp`) para `0x7E00`.
5. O kernel assume a execução, valida o VM e imprime a **string de resposta** na
   tela do QEMU.

## Notas
A execução desta atividade contou com **auxílio de IA** para entender o enunciado
e orquestrar as etapas do trabalho (planejamento, verificações e organização do
repositório). O código e a resposta final foram revisados e validados pelo aluno.
