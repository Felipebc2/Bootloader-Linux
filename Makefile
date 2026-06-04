ASM    = bootloader.s
BIN    = bootloader
DISK   = disco.img
KERNEL = kernel

$(BIN): $(ASM)
	as -o bootloader.o $(ASM)
	ld -o $(BIN) --oformat binary -Ttext 0x7c00 bootloader.o

check: $(BIN)
	@echo "Tamanho (deve ser 512):" && wc -c $(BIN)
	@echo "Ultimos bytes (deve terminar 55 aa):" && hexdump -C $(BIN) | tail -n 2

boot: $(BIN)
	qemu-system-x86_64 $(BIN)

boot-curses: $(BIN)
	qemu-system-x86_64 -display curses $(BIN)

disk: $(BIN) $(KERNEL)
	dd if=/dev/zero of=$(DISK) bs=1024 count=720
	dd if=$(BIN) of=$(DISK) conv=notrunc seek=0
	dd if=$(KERNEL) of=$(DISK) conv=notrunc bs=512 seek=1

run: disk
	qemu-system-x86_64 $(DISK)

run-curses: disk
	qemu-system-x86_64 -display curses $(DISK)

debug: disk
	qemu-system-x86_64 -s -S $(DISK)

clean:
	rm -f bootloader.o $(BIN) $(DISK)

.PHONY: check boot boot-curses disk run run-curses debug clean
