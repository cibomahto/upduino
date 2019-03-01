
TARGET = pwm_wtf

VERILOG_FILES = \
	chip.v \
	sync.v \
	dmx_in.v \
	pwm_out.v \
	pwm_channel.v

PIN_CONFIG_FILE = pwm_wtf_reva.pcf
CLOCK_CONSTRAINTS_FILE = clocks.py

#$(TARGET).bin: $(VERILOG_FILES) $(PIN_CONFIG_FILE)
#	yosys -q -p "synth_ice40 -blif $(TARGET).blif" $(VERILOG_FILES)
#	arachne-pnr -d 5k -P sg48 -p $(PIN_CONFIG_FILE) $(TARGET).blif -o $(TARGET).txt
#	icepack $(TARGET).txt $(TARGET).bin

default: $(TARGET).bin

$(TARGET).json: $(VERILOG_FILES)
	yosys -q -p "synth_ice40 -top chip -json $(TARGET).json" -l $(TARGET)-yosys.log $(VERILOG_FILES)

$(TARGET).asc: $(TARGET).json $(PIN_CONFIG_FILE) $(CLOCK_CONSTRAINTS_FILE)
	nextpnr-ice40 \
		--up5k \
		--pre-pack $(CLOCK_CONSTRAINTS_FILE) \
		--json $(TARGET).json \
		--pcf $(PIN_CONFIG_FILE) \
		--asc $(TARGET).asc \
		-l $(TARGET)-nextpnr.log

$(TARGET).bin: $(TARGET).asc
	icepack $(TARGET).asc $(TARGET).bin

stats: $(TARGET).json $(TARGET).asc
	sed -n '/=== chip ===/,/6\.28/p' $(TARGET)-yosys.log
	sed -n '/Info: Device utilisation/,/Info: Placed/p' $(TARGET)-nextpnr.log

#.PHONY: flash
#flash: $(TARGET).bin
#	iceprog $(TARGET).bin

.PHONY: flash
flash: $(TARGET).bin
	./flash.py $(TARGET).bin
#	./capture.py
#	wmctrl -a "Saleae Logic Software"

.PHONY: clean
clean:
	$(RM) -f \
		$(TARGET).json \
		$(TARGET).asc \
		$(TARGET)-yosys.log \
		$(TARGET)-nextpnr.log \
		$(TARGET).bin
