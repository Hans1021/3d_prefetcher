TOP = tb_prefetcher_3d

RTL = ../rtl/prefetcher_3d.sv
TB  = tb_prefetcher_3d.sv

VERILATOR = verilator

all: run

build:
	$(VERILATOR) --binary --timing --trace -Wall \
	$(RTL) $(TB) \
	--top-module $(TOP)

run: build
	./obj_dir/V$(TOP)

clean:
	rm -rf obj_dir
	rm -f waveform.vcd