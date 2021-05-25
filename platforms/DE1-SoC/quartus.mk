#TOP_LEVEL_ENTITY = $(shell grep -v '\#' $(PROJECT).qsf | grep TOP_LEVEL_ENTITY | cut -d " " -f 4)

STA_TCL = sta.tcl

all: summary

map: $(PROJECT).map.rpt
fit: $(PROJECT).fit.rpt
asm: $(PROJECT).asm.rpt
sta: $(PROJECT).sta.rpt

MAP_ARGS = --read_settings_files=on --write_settings_files=off
FIT_ARGS = --read_settings_files=on --write_settings_files=off
ASM_ARGS = 
STA_ARGS =

test:
	@echo $(SOURCE_FILES)

gen: $(SOURCE_FILES)


$(PROJECT).map.rpt: $(SOURCE_FILES) $(PROJECT).qsf
	quartus_map $(MAP_ARGS) $(PROJECT)

$(PROJECT).fit.rpt: $(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)

$(PROJECT).asm.rpt: $(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: $(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT) 

timing: $(PROJECT).sta.rpt $(STA_TCL)
	quartus_sta -t $(STA_TCL)

summary: $(PROJECT).sta.rpt
	@echo ""
	@grep -B 1 -A 5 "; Clocks *;" $^
	@echo ""
	@grep -B 1 -A 5 "; Slow 1100mV 85C Model Fmax Summary *;" $^
	@echo ""
	@grep -B 1 -A 5 "; Slow 1100mV 85C Model Setup Summary ;" $^
	@echo ""
	@grep -B 1 -A 5 "; Slow 1100mV 85C Model Hold Summary ;" $^
	@echo ""

resources: $(PROJECT).fit.rpt
	grep -B 1 -A 30 "; Fitter Summary" $(PROJECT).fit.rpt

sof: $(PROJECT).asm.rpt
	@echo ""

program: $(PROJECT).asm.rpt $(PROJECT).sof
	cp $(PROJECT).sof proj.sof
	quartus_pgm --no_banner --mode=jtag proj.cdf -o "P;$(PROJECT).sof"
 
quartus_clean:
	rm -rf $(PROJECT).sof *.sof $(PROJECT).*.rpt $(PROJECT).htm $(PROJECT).eqn $(PROJECT).pin $(PROJECT).sof $(PROJECT).pof $(PROJECT).done $(PROJECT).qws db incremental_db $(PROJECT).*.smsg $(PROJECT).*.summary $(PROJECT).cdf $(PROJECT).qpf $(PROJECT).jdi $(PROJECT).sld c5_pin_model_dump.txt

