#!/usr/bin/env python3
# Calculo do Verificador da Matricula (VM) do T02.
# d_i e o digito na posicao i da matricula, da esquerda para a direita, comecando
# em i=1; n e o numero de digitos.
#   VM_A (interpretacao oficial, eq. 1 do requisito): ( sum_{i=1..n} (d_i*i)^3 ) mod 4093
#   VM_B (alternativa guardada por seguranca):        ( sum_{i=1..n}  d_i*i   )^3 mod 4093
# O bootloader insere VM_A (em hex) no registrador AX. Imprime ambos em decimal e
# hexadecimal para conferencia.

MATRICULA = "2311292"
MOD = 4093

digitos = [int(c) for c in MATRICULA]
n = len(digitos)

vm_a = sum((d * (i + 1)) ** 3 for i, d in enumerate(digitos)) % MOD
vm_b = (sum(d * (i + 1) for i, d in enumerate(digitos)) ** 3) % MOD

print(f"Matricula: {MATRICULA}  (n={n} digitos)")
print(f"VM_A (oficial) = {vm_a}  =  0x{vm_a:04X}")
print(f"VM_B (alt)     = {vm_b}  =  0x{vm_b:04X}")
