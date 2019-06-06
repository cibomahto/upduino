TARGET = supersweet

VERILOG_FILES = \
	chip.v \
	sync.v \
	blink.v \
	matrix.v \
	dmx_in.v

PIN_CONFIG_FILE = upduino_v2.pcf
CLOCK_CONSTRAINTS_FILE = clocks.py

default: $(TARGET).bin

pll.v:
	icepll -i 12 -o 30 -f pll.v -m

$(TARGET).json: $(VERILOG_FILES)
	yosys \
		-q \
		-p "synth_ice40 -top chip -json $(TARGET).json" \
		-l $(TARGET)-yosys.log \
		$(VERILOG_FILES)

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

.PHONY: flash
flash: $(TARGET).bin
	iceprog $(TARGET).bin

.PHONY: flashpy
flashpy: $(TARGET).bin
	./flash.py $(TARGET).bin

.PHONY: upload
upload: $(TARGET).bin
	./upload.sh

.PHONY: clean
clean:
	$(RM) -f \
		$(TARGET).json \
		$(TARGET).asc \
		$(TARGET)-yosys.log \
		$(TARGET)-nextpnr.log \
		$(TARGET).bin
