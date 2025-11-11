PROJNM=Atari2600_Basys3
SRCDIR=$(PROJNM).srcs
SCRIPTDIR=$(SRCDIR)/scripts_1
SOURCES= \
	$(SRCDIR)/constrs_1/Basys-3-Master.xdc		\
	$(SRCDIR)/sources_1/roms/colortab.mem		\
	$(SRCDIR)/sources_1/roms/cart.mem		\
	$(SRCDIR)/sources_1/atari2600_top.v		\
	$(SRCDIR)/sources_1/ps2/atari2600ps2.v		\
	$(SRCDIR)/sources_1/ps2/ps2_intf.v		\
	$(SRCDIR)/sources_1/atarihw/atari2600tia.v	\
	$(SRCDIR)/sources_1/atarihw/atari2600tiamis.v	\
	$(SRCDIR)/sources_1/atarihw/atari2600tiaball.v	\
	$(SRCDIR)/sources_1/atarihw/ataricart.v		\
	$(SRCDIR)/sources_1/atarihw/atari2600tiaplay.v	\
	$(SRCDIR)/sources_1/atarihw/riot6532.v		\
	$(SRCDIR)/sources_1/atarihw/atari2600hw.v	\
	$(SRCDIR)/sources_1/cpu6502/cpu6502.v		\
	$(SRCDIR)/sources_1/Atari2600_Basys3.v

ifndef XILINX_VIVADO
$(error XILINX_VIVADO must be set to point to Xilinx tools)
endif

VIVADO=$(XILINX_VIVADO)/bin/vivado
XSDB=$(XILINX_VIVADO)/bin/xsdb

.PHONY: default project bitstream program

default: project

PROJECT_FILE=$(PROJNM)/$(PROJNM).xpr

project: $(PROJECT_FILE)

$(PROJECT_FILE):
ifeq ("","$(wildcard $(PROJECT_FILE))")
	$(VIVADO) -mode batch -source $(PROJNM).tcl
else
	@echo Project already exists.
endif

BITSTREAM=$(PROJNM)/$(PROJNM).runs/impl_1/$(PROJNM).bit

bitstream: $(BITSTREAM)

$(BITSTREAM): $(SOURCES) $(ROMS) $(PROJECT_FILE)
	@echo Building $(BITSTREAM) from sources
	$(VIVADO) -mode batch -source \
		$(SCRIPTDIR)/bitstream.tcl -tclargs $(PROJNM)

program:
	@echo Programming device
	$(XSDB) -eval "connect ; fpga -file $(BITSTREAM)"

# You can create an MMI file which can be used ith updatemem to load
# a new binary into the cartridge without resynthesizing.
mmi:
	$(VIVADO) -mode batch -source $(SCRIPTDIR)/write_mmi.tcl \
		-tclargs $(PROJECT_FILE)
