.SUFFIXES:

WORK ?= work
SRCDIR  ?= src
OUTDIR  ?= out
WORKDIR ?= build
VHDLSTD ?= 08

VHDLFLAGS = --std=$(VHDLSTD) --work=$(WORK)

SRCFILES = $(strip $(wildcard $(SRCDIR)/*.vhd))

CONTENTFILE = $(WORKDIR)/$(WORK)-obj$(VHDLSTD).cf

.PHONY: help clean

define HELP_TEXT =
Uso:
	make help : Muestra este mensaje
	make $(OUTDIR)/<entidad>.ghw : ejecuta la simulación definida en la entidad <entidad> y guarda el resultado en $(OUTDIR)/<entidad>.ghw
	make clean : borra todos los archivos generados en $(OUTDIR) y $(SIMDIR)
	make $(OUTDIR)/<entidad>.bin : realiza la síntesis lógica para FPGA hx4k de la entidad <entidad>. Requiere el archivo de especificación de pines $(SRCDIR)/<entidad>.pcf
	make $(OUTDIR)/<entidad>.load : carga en la FPGA hx4k $(OUTDIR)/<entidad>.bin
endef

help:
	@echo $(info $(HELP_TEXT))

clean:
ifneq ($(wildcard $(OUTDIR)/*),)
	rm $(wildcard $(OUTDIR)/*)
endif
ifneq ($(wildcard $(WORKDIR)/*),)
	rm -r $(wildcard $(WORKDIR)/*)
endif

$(OUTDIR):
	mkdir -p $(OUTDIR)
$(WORKDIR):
	mkdir -p $(WORKDIR)

$(CONTENTFILE): $(SRCFILES) | $(WORKDIR)
	cd $(WORKDIR) && ghdl -i $(VHDLFLAGS) $(abspath $(SRCFILES))

$(OUTDIR)/%.ghw: $(CONTENTFILE) | $(OUTDIR)
	cd $(WORKDIR) && ghdl -m $(VHDLFLAGS) $(*F)
	cd $(WORKDIR) && ghdl -r $(VHDLFLAGS) $(*F) --wave=../$(OUTDIR)/$(*F).ghw 2>&1 | tee $(*F).log

$(OUTDIR)/%.bin: $(SRCDIR)/%.pcf $(CONTENTFILE) | $(OUTDIR)
	cd $(WORKDIR) && ghdl -m $(VHDLFLAGS) $(*F)
	cd $(WORKDIR) && ghdl --synth $(VHDLFLAGS) --out=verilog $(*F) > $(*F).v
	cd $(WORKDIR) && yosys -q -p "read_verilog $(*F).v ; synth_ice40 -json sintesis_$(*F).json -top $(*F)" -l sintesis_$(*F).json.log
	cd $(WORKDIR) && nextpnr-ice40 --hx4k --json sintesis_$(*F).json --pcf ../$(SRCDIR)/$(*F).pcf --package tq144 --asc $(*F).asc --log $(*F).pnr_log
	cd $(WORKDIR) && icepack $(*F).asc ../$(OUTDIR)/$(*F).bin

$(OUTDIR)/%.load: $(OUTDIR)/%.bin
	iceprog $<
