# 3D Prefetcher Arithmetic Optimization

This document compares the baseline 3D prefetcher against two alternative implementations designed to reduce the hardware cost of dynamic division and modulo operations.

## Baseline

The baseline implementation derives the 3D coordinates from the flattened address using:

- `x = addr % X_SIZE`
- `y = (addr / X_SIZE) % Y_SIZE`
- `z = addr / (X_SIZE * Y_SIZE)`

This approach is straightforward and readable, but it uses dynamic division and modulo operations. When the divisors are not powers of two, these operations can synthesize into relatively large combinational logic.

## Reduced-Arithmetic Version

The reduced-arithmetic implementation removes all division operations.

It uses:

- `row_position = addr % X_SIZE`
- `plane_position = addr % PLANE_SIZE`

where:

- `PLANE_SIZE = X_SIZE * Y_SIZE`

Boundary validity is then determined from these positions:

- X boundaries are determined from `row_position`.
- Y boundaries are determined from `plane_position`.
- Z boundaries are determined directly from comparisons against `PLANE_SIZE`.

This version therefore reduces the coordinate-recovery logic from multiple division/modulo operations to two modulo operations and several comparisons.

## Comparison-Only Version

The comparison-only implementation removes both division and modulo.

Instead, boundary locations are generated using parameterized loops.

For X boundaries, the implementation checks the start and end address of each row.

For Y boundaries, the implementation checks the first and last row of each plane.

Z boundaries are determined directly from comparisons against `PLANE_SIZE`.

Because the loop limits depend only on parameters, the loops are expanded during synthesis into fixed comparison logic.

This can produce very small hardware for small fixed grid dimensions, but the number of generated comparisons grows with the configured dimensions.

## Synthesis Method

All implementations were synthesized using Yosys 0.33.

The synthesis flow used:

```text
read_verilog -sv <rtl>;
chparam -set X_SIZE <X> -set Y_SIZE <Y> -set Z_SIZE <Z> <top>;
hierarchy -top <top>;
synth -top <top>;
stat;
```

The final generic Yosys cell count was used as a structural-area proxy.

These results are not physical silicon area or timing measurements. A target standard-cell library and physical design flow would be required for actual area and timing results.

## Representative Results

| Configuration | Baseline | Reduced | Compare-only |
| --- | ---: | ---: | ---: |
| 3x3x3 | 15097 | 10638 | 735 |
| 4x3x2 | 10303 | 5763 | 915 |
| 7x5x4 | 14237 | 10085 | 873 |
| 8x8x8 | 1029 | 1106 | 1701 |
| 17x13x9 | 13086 | 9570 | 1819 |

For the tested non-power-of-two configurations, the comparison-only implementation was substantially smaller than both arithmetic implementations at small grid sizes.

The 8x8x8 case behaves differently. Because 8 and 64 are powers of two, division and modulo can be reduced to shifts or bit selection during synthesis. In this case, the baseline implementation becomes the smallest design.

## Scaling and Crossover Study

A larger cube sweep was performed to determine when the generated comparison logic becomes more expensive than the arithmetic-based implementations.

| Cube Size | Baseline | Reduced | Compare-only |
| --- | ---: | ---: | ---: |
| 34x34x34 | 12594 | 9493 | 9395 |
| 35x35x35 | 12010 | 8911 | 9753 |
| 39x39x39 | 11891 | 8807 | 11812 |
| 40x40x40 | 12489 | 9420 | 11848 |
| 41x41x41 | 12081 | 8966 | 12802 |

The comparison-only implementation first exceeds the reduced-arithmetic implementation at 35x35x35.

It first exceeds the baseline implementation at 41x41x41.

The comparison-only implementation therefore performs very well for small fixed dimensions, but its area grows significantly as the number of generated boundary comparisons increases.

The arithmetic implementations do not scale monotonically with dimension size because the synthesized cost of constant division and modulo depends strongly on the specific divisor values.

## Conclusion

The three implementations have different tradeoffs:

- The baseline is the simplest and most direct implementation, but dynamic division and modulo can be expensive for arbitrary non-power-of-two dimensions.
- The reduced-arithmetic implementation removes division and significantly reduces arithmetic cost while maintaining good scaling.
- The comparison-only implementation is extremely efficient for small fixed dimensions, but its generated comparison logic scales poorly as the grid dimensions increase.
- Power-of-two dimensions are a special case because division and modulo can synthesize into very inexpensive shift or bit-selection logic.

For the tested Yosys configurations, the reduced-arithmetic implementation provides the best general-purpose tradeoff for larger arbitrary dimensions, while the comparison-only implementation is attractive for small fixed grids.
