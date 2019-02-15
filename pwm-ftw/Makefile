
TARGET = pwm_wtf

VERILOG_FILES = \
	chip.v \
	pwm.v \
	sync.v \
	spireader.v

PIN_CONFIG_FILE = pwm_wtf_reva.pcf

#$(TARGET).bin: $(VERILOG_FILES) $(PIN_CONFIG_FILE)
#	yosys -q -p "synth_ice40 -blif $(TARGET).blif" $(VERILOG_FILES)
#	arachne-pnr -d 5k -P sg48 -p $(PIN_CONFIG_FILE) $(TARGET).blif -o $(TARGET).txt
#	icepack $(TARGET).txt $(TARGET).bin

$(TARGET).bin: $(VERILOG_FILES) $(PIN_CONFIG_FILE)
	yosys -q -p "synth_ice40 -top chip -json $(TARGET).json" $(VERILOG_FILES)
	nextpnr-ice40 --up5k --json $(TARGET).json --pcf $(PIN_CONFIG_FILE) --asc $(TARGET).asc --freq 40
	icepack $(TARGET).asc $(TARGET).bin


.PHONY: flash
flash: $(TARGET).bin
	iceprog $(TARGET).bin

flashpy: $(TARGET).bin
	./flash.py $(TARGET).bin

.PHONY: clean
clean:
	$(RM) -f $(TARGET).blif $(TARGET).txt $(TARGET).ex $(TARGET).bin
