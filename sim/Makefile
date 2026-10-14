VERILATOR = verilator

all: baseline

baseline:
	$(VERILATOR) --binary --timing --trace -Wall \
	../rtl/prefetcher_3d.sv \
	tb_prefetcher_3d.sv \
	--top-module tb_prefetcher_3d
	./obj_dir/Vtb_prefetcher_3d

reduced:
	rm -rf obj_dir
	$(VERILATOR) --binary --timing --trace -Wall \
	../rtl/prefetcher_3d_reduced.sv \
	tb_prefetcher_3d_reduced.sv \
	--top-module tb_prefetcher_3d_reduced
	./obj_dir/Vtb_prefetcher_3d_reduced

compare:
	rm -rf obj_dir
	$(VERILATOR) --binary --timing --trace -Wall \
	../rtl/prefetcher_3d_compare.sv \
	tb_prefetcher_3d_compare.sv \
	--top-module tb_prefetcher_3d_compare
	./obj_dir/Vtb_prefetcher_3d_compare

clean:
	rm -rf obj_dir
	rm -f waveform.vcd