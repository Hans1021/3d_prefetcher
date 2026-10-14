#!/bin/bash
set -e

mkdir -p results_crossover

run_one () {
    NAME=$1
    RTL=$2
    TOP=$3
    N=$4

    echo "========================================"
    echo "$NAME : ${N}x${N}x${N}"
    echo "========================================"

    yosys -p "
        read_verilog -sv $RTL;
        chparam -set X_SIZE $N -set Y_SIZE $N -set Z_SIZE $N $TOP;
        hierarchy -top $TOP;
        synth -top $TOP;
        stat;
    " | tee results_crossover/${NAME}_${N}x${N}x${N}.log
}

for N in {32..41}
do
    run_one baseline \
        ../rtl/prefetcher_3d.sv \
        prefetcher_3d \
        $N

    run_one reduced \
        ../rtl/prefetcher_3d_reduced.sv \
        prefetcher_3d_reduced \
        $N

    run_one compare \
        ../rtl/prefetcher_3d_compare.sv \
        prefetcher_3d_compare \
        $N
done