#!/bin/bash
set -e

mkdir -p results

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
    " | tee results/${NAME}_${X}x${Y}x${Z}.log
}

for SIZE in \
    "3 3 3" \
    "4 3 2" \
    "8 8 8" \
    "7 5 4" \
    "17 13 9"
do
    read X Y Z <<< "$SIZE"

    run_one baseline \
        ../rtl/prefetcher_3d.sv \
        prefetcher_3d \
        $X $Y $Z

    run_one reduced \
        ../rtl/prefetcher_3d_reduced.sv \
        prefetcher_3d_reduced \
        $X $Y $Z

    run_one compare \
        ../rtl/prefetcher_3d_compare.sv \
        prefetcher_3d_compare \
        $X $Y $Z
done