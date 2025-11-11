
BIN2MEM=/usr/bin/hexdump -v -e '/1 "%02X\n"'

TARGETS=cart.mem

cart.mem: cart.bin

%.mem: %.bin
	echo "@0000" > $@
	$(BIN2MEM) $< >> $@
