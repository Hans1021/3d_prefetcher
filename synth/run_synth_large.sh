#!/bin/bash
set -e

mkdir -p results_large

run_one () {
    NAME=$1
    RTL=$2
    TOP=$3
    X=$4
    Y=$5
    Z=$6

    echo "========================================"
    echo "$NAME : ${X}x${Y}x${Z}"
    echo "========================================"

    yosys -p "
        read_verilog -sv $RTL;
        chparam -set X_SIZE $X -set Y_SIZE $Y -set Z_SIZE $Z $TOP;
        hierarchy -top $TOP;
        synth -top $TOP;
        stat;
    " | tee results_large/${NAME}_${X}x${Y}x${Z}.log
}

for N in \
    21 \
    31 \
    41 \
    51 \
    63 \
    79 \
    95 \
    127
do
    run_one baseline \
        ../rtl/prefetcher_3d.sv \
        prefetcher_3d \
        $N $N $N

    run_one reduced \
        ../rtl/prefetcher_3d_reduced.sv \
        prefetcher_3d_reduced \
        $N $N $N

    run_one compare \
        ../rtl/prefetcher_3d_compare.sv \
        prefetcher_3d_compare \
        $N $N $N
done