# Fase 2 - Impressao de caractere via int 0x10
# Bootloader em modo real (16 bits). Imprime o caractere 'A' (0x41) na tela
# usando o servico de teletype da BIOS (int 0x10, AH=0x0E; BH=0x00 = pagina 0).
# Depois executa hlt para parar a CPU. O setor e preenchido com zeros ate 510
# bytes e fechado com a assinatura MBR 0x55 0xaa, totalizando 512 bytes.

.code16
.intel_syntax noprefix
.global _start

_start:
    mov al, 0x41
    mov ah, 0x0E
    mov bh, 0x00
    int 0x10
    hlt

.fill 510-(.-_start), 1, 0
.byte 0x55, 0xaa
