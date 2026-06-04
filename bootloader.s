# Fase 1 - Hello World (512 bytes + assinatura de boot)
# Bootloader em modo real (16 bits). _start cai num loop infinito, entao a CPU
# fica girando e o QEMU mostra a tela com o cursor. O setor e preenchido com
# zeros ate 510 bytes e fechado com a assinatura MBR 0x55 0xaa (bytes 510-511),
# totalizando exatamente 512 bytes.

.code16
.global _start

_start:
    jmp _start

.fill 510-(.-_start), 1, 0
.byte 0x55, 0xaa
