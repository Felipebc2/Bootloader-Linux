# Fase 3 - Bootloader completo (secao 4.3)
# Bootloader em modo real (16 bits) que carrega o kernel e salta para ele.
# Passos: desabilita interrupcoes (cli), zera os segmentos DS/ES/SS e aponta a
# pilha para 0x7c00, reabilita interrupcoes (sti). Reseta o controlador de disco
# (int 0x13, AH=0) e le 4 setores a partir do setor 2 do disco para ES:BX =
# 0x7E0:0x0000 (= endereco fisico 0x7E00), usando int 0x13 AH=0x02. DL nao e
# alterado (e o drive de boot que a BIOS deixou). Em AX fica o Verificador da
# Matricula (0x0000 por enquanto; sera preenchido na Fase 4) e entao salta para o
# kernel em 0x7E00. O setor e preenchido com zeros ate 510 bytes e fechado com a
# assinatura MBR 0x55 0xaa, totalizando 512 bytes.

.code16
.intel_syntax noprefix
.global _start

_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    xor ah, ah
    int 0x13

    mov ax, 0x07E0
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, 0x04
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    int 0x13

    mov ax, 0x0000
    jmp 0x7E00

.fill 510-(.-_start), 1, 0
.byte 0x55, 0xaa
