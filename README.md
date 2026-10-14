# 3D Spatial Prefetcher

## Overview

This project implements a parameterized 3D spatial prefetcher in SystemVerilog.

The prefetcher takes an address corresponding to a point in a 3D structure and outputs the addresses of all valid adjacent points, one per clock cycle.

The project began with a fixed `3 x 3 x 3` implementation and was then generalized to support arbitrary:

```text
X_SIZE x Y_SIZE x Z_SIZE
```

dimensions.

After the parameterized implementation was completed, two additional versions were developed to investigate the hardware cost of division and modulo operations used for coordinate recovery:

- **Baseline** — reconstructs x, y, and z coordinates using division and modulo.
- **Reduced-arithmetic** — removes all division and uses only two modulo operations.
- **Comparison-only** — removes both division and modulo and instead generates boundary-comparison logic.

The implementations were verified using Verilator and synthesized with Yosys to compare their resulting logic complexity.

---

## Interface

All three implementations use the same interface.

| Signal | Direction | Description |
| --- | --- | --- |
| `clk` | Input | Clock |
| `reset` | Input | Resets state |
| `address_i` | Input | Input address |
| `valid` | Input | Indicates `address_i` is valid |
| `address_o` | Output | Prefetched output address |
| `ready` | Output | Indicates `address_o` is valid |

The prefetcher accepts a new input only while in `IDLE`.

If `valid` is asserted while a previous request is still being processed, the new input is not accepted.

`ready` is used as an output-valid signal. When `ready = 1`, `address_o` contains a valid neighboring address.

---

## Address Mapping

The 3D structure is flattened into a linear address space.

The x coordinate changes fastest, followed by y, then z.

For a parameterized:

```text
X_SIZE x Y_SIZE x Z_SIZE
```

structure, the valid address range is:

```text
0 to X_SIZE * Y_SIZE * Z_SIZE - 1
```

The neighbor address offsets are:

```text
x: +/- 1
y: +/- X_SIZE
z: +/- (X_SIZE * Y_SIZE)
```

For example, in a `3 x 3 x 3` structure:

### z = 0

```text
0  1  2
3  4  5
6  7  8
```

### z = 1

```text
9  10 11
12 13 14
15 16 17
```

### z = 2

```text
18 19 20
21 22 23
24 25 26
```

The corresponding offsets are:

```text
x neighbors: +/- 1
y neighbors: +/- 3
z neighbors: +/- 9
```

For address `13`, which is the center of the cube, the valid neighboring addresses are:

```text
12, 14, 10, 16, 4, 22
```

---

## FSM Design

The prefetcher uses the following FSM:

```text
IDLE
  -> X_MINUS
  -> X_PLUS
  -> Y_MINUS
  -> Y_PLUS
  -> Z_MINUS
  -> Z_PLUS
  -> IDLE
```

Each directional state corresponds to one possible neighboring address.

Invalid directions are skipped when selecting the next state, allowing valid output addresses to be generated on consecutive cycles without unnecessary dead cycles.

While a valid neighbor is being output:

```text
ready = 1
```

and `address_o` contains the corresponding neighboring address.

While in `IDLE`:

```text
ready = 0
```

---

## Storing the Input Address

One request can require several cycles because a point may have up to six valid neighbors.

The accepted request is copied into:

```text
stored_address
```

so the external `address_i` signal does not need to remain unchanged while the request is being processed.

After leaving `IDLE`, neighbor generation uses `stored_address`.

One timing issue appeared when this register was first introduced. While still in `IDLE`, the newly accepted value has not yet reached `stored_address` before the active clock edge.

To avoid selecting the first neighbor using the previous request, the design uses the live `address_i` value while in `IDLE` and switches to `stored_address` after the request has been accepted.

---

## Baseline Parameterized Design

The baseline parameterized implementation is:

```text
rtl/prefetcher_3d.sv
```

It reconstructs the three coordinates from the flattened address using:

```text
x = addr % X_SIZE
y = (addr / X_SIZE) % Y_SIZE
z = addr / (X_SIZE * Y_SIZE)
```

The coordinates are then used to determine which neighboring directions are valid.

The boundary conditions are:

```text
X_MINUS valid if X_SIZE > 1 and x > 0
X_PLUS  valid if X_SIZE > 1 and x < X_SIZE - 1

Y_MINUS valid if Y_SIZE > 1 and y > 0
Y_PLUS  valid if Y_SIZE > 1 and y < Y_SIZE - 1

Z_MINUS valid if Z_SIZE > 1 and z > 0
Z_PLUS  valid if Z_SIZE > 1 and z < Z_SIZE - 1
```

### Coordinate Widths

Coordinate widths are calculated using `$clog2`.

A minimum width of 1 bit is used so dimensions of size 1 remain legal:

```text
X_BITS = (X_SIZE <= 1) ? 1 : ceil(log2(X_SIZE))
Y_BITS = (Y_SIZE <= 1) ? 1 : ceil(log2(Y_SIZE))
Z_BITS = (Z_SIZE <= 1) ? 1 : ceil(log2(Z_SIZE))
```

Explicit sized casts are used where necessary to make truncation and width conversion intentional.

If a dimension has size 1, both directions on that axis are disabled.

For example, if:

```text
X_SIZE = 1
```

then neither `X_MINUS` nor `X_PLUS` can be valid.

### Invalid Addresses

Out-of-range requests are ignored.

A request is accepted only when:

```text
address_i < X_SIZE * Y_SIZE * Z_SIZE
```

Otherwise, the FSM remains in `IDLE` and produces no output.

---

## Verification

The baseline parameterized implementation was tested using several structures.

### 3 x 3 x 3

| Input | Position | Expected Outputs |
| ---: | --- | --- |
| `0` | Corner | `1, 3, 9` |
| `13` | Center | `12, 14, 10, 16, 4, 22` |
| `26` | Corner | `25, 23, 17` |
| `10` | Face | `9, 11, 13, 1, 19` |
| `9` | Edge | `10, 12, 0, 18` |

Terminal results:

![3x3x3 terminal results](docs/screenshots/3x3x3_terminal.png)

Waveform:

![3x3x3 waveform](docs/screenshots/3x3x3_waveform.png)

### 4 x 3 x 2

For this configuration:

```text
x offset = 1
y offset = 4
z offset = 12
```

For address `17`, the expected output sequence is:

```text
16, 18, 13, 21, 5
```

The design was also tested with invalid address `24`, which correctly produced no outputs.

Terminal results:

![Parameterized terminal results](docs/screenshots/parameterized_terminal.png)

Waveform:

![4x3x2 waveform](docs/screenshots/4x3x2_waveform.png)

### 1 x 3 x 3

This case verifies support for dimensions of size 1.

For address `4`, the expected outputs are:

```text
3, 5, 1, 7
```

with no x-direction neighbors.

Waveform:

![1x3x3 waveform](docs/screenshots/1x3x3_waveform.png)

The optimized implementations were also simulated against the same behavior and produced the same output sequences as the baseline design.

---

## Arithmetic Optimization

The baseline implementation is simple to understand, but its coordinate reconstruction contains dynamic division and modulo operations.

Division and modulo by arbitrary constants can synthesize into substantial combinational logic.

Two alternative implementations were therefore developed.

### Reduced-Arithmetic Version

File:

```text
rtl/prefetcher_3d_reduced.sv
```

This implementation removes all division operations.

Instead of reconstructing x, y, and z individually, it calculates:

```text
row_position   = addr % X_SIZE
plane_position = addr % PLANE_SIZE
```

where:

```text
PLANE_SIZE = X_SIZE * Y_SIZE
```

Boundary checks are then derived directly from these positions.

The validity conditions are equivalent to:

```text
x_minus_valid =
    X_SIZE > 1 &&
    row_position > 0

x_plus_valid =
    X_SIZE > 1 &&
    row_position < X_SIZE - 1

y_minus_valid =
    Y_SIZE > 1 &&
    plane_position >= X_SIZE

y_plus_valid =
    Y_SIZE > 1 &&
    plane_position < PLANE_SIZE - X_SIZE

z_minus_valid =
    Z_SIZE > 1 &&
    addr >= PLANE_SIZE

z_plus_valid =
    Z_SIZE > 1 &&
    addr < TOTAL_SIZE - PLANE_SIZE
```

where:

```text
TOTAL_SIZE = X_SIZE * Y_SIZE * Z_SIZE
```

This removes all `/` operations and leaves only two `%` operations.

---

### Comparison-Only Version

File:

```text
rtl/prefetcher_3d_compare.sv
```

This implementation removes both division and modulo.

Instead, boundary positions are generated using parameterized loops.

For X boundaries, each row start and row end are checked.

Conceptually:

```text
row start = row * X_SIZE
row end   = row * X_SIZE + X_SIZE - 1
```

For Y boundaries, the first and last row of each plane are checked.

Z boundaries are still determined directly using comparisons against `PLANE_SIZE`.

Because the loop bounds are parameters known during elaboration, synthesis expands these loops into fixed comparison logic.

This is extremely efficient for small grid dimensions, but the number of comparisons grows as the configured dimensions increase.

---

## Synthesis

The three implementations were synthesized using Yosys 0.33.

The general synthesis flow was:

```text
read_verilog -sv <rtl>;
chparam -set X_SIZE <X> -set Y_SIZE <Y> -set Z_SIZE <Z> <top>;
hierarchy -top <top>;
synth -top <top>;
stat;
```

The final generic Yosys cell count is used as a structural-area proxy.

These counts are not physical silicon area or timing measurements. Actual area and timing would require mapping to a target standard-cell library and running an appropriate backend flow.

---

## Representative Synthesis Results

| Configuration | Baseline | Reduced | Compare-only |
| --- | ---: | ---: | ---: |
| 3 x 3 x 3 | 15097 | 10638 | **735** |
| 4 x 3 x 2 | 10303 | 5763 | **915** |
| 7 x 5 x 4 | 14237 | 10085 | **873** |
| 8 x 8 x 8 | **1029** | 1106 | 1701 |
| 17 x 13 x 9 | 13086 | 9570 | **1819** |

For small, non-power-of-two configurations, the comparison-only implementation synthesizes to dramatically fewer generic cells.

The `8 x 8 x 8` case is different.

Because the relevant divisors are powers of two, division and modulo can be reduced to shifts, masks, or bit selections during synthesis. In this case, the baseline arithmetic implementation becomes the smallest version.

---

## Scaling and Crossover

A larger cube sweep was performed to determine when the generated comparison logic becomes more expensive than the arithmetic implementations.

Representative crossover-region results are:

| Cube Size | Baseline | Reduced | Compare-only |
| --- | ---: | ---: | ---: |
| 34 x 34 x 34 | 12594 | 9493 | **9395** |
| 35 x 35 x 35 | 12010 | **8911** | 9753 |
| 39 x 39 x 39 | 11891 | **8807** | 11812 |
| 40 x 40 x 40 | 12489 | **9420** | 11848 |
| 41 x 41 x 41 | 12081 | **8966** | 12802 |

The comparison-only implementation first becomes larger than the reduced-arithmetic implementation at:

```text
35 x 35 x 35
```

It first becomes larger than the baseline implementation at:

```text
41 x 41 x 41
```

The generated comparison logic therefore works very well for small fixed dimensions but scales poorly as the number of row and plane boundaries increases.

The arithmetic implementations do not scale monotonically with dimension size because the synthesized cost of division and modulo depends strongly on the specific constant divisors.

For the tested Yosys configurations, the reduced-arithmetic implementation provides the best general-purpose tradeoff for larger arbitrary dimensions.

More detailed optimization and synthesis notes are available in [notes_optimization](docs/notes_optimization.md).

---

## Challenges and Design Decisions

### Understanding the Address Mapping

The input interface provides only a flattened address rather than explicit x, y, and z coordinates.

The design therefore treats the structure as a flattened 3D array.

This allows neighboring addresses to be determined using row and plane sizes.

---

### Preventing Boundary Wraparound

Simply adding or subtracting the neighbor offsets is not sufficient.

For example, subtracting 1 normally represents `X_MINUS`, but if the point is already at `x = 0`, the resulting address belongs to the previous row rather than representing a valid x neighbor.

Each implementation therefore determines whether a direction is valid before entering the corresponding FSM state.

---

### Producing Multiple Outputs from One Input

A point may have between three and six valid adjacent neighbors, while the interface provides only one output address.

The directional FSM allows these addresses to be emitted sequentially, one per cycle.

Invalid directions are skipped.

---

### Input Address Changing During Processing

A request requires several cycles.

Using `address_i` directly throughout processing would require the source to hold the input constant.

The accepted request is therefore stored internally in `stored_address`.

---

### First-State Timing

The newly accepted address does not appear in `stored_address` until the active clock edge.

The first next-state decision therefore uses the live `address_i`.

After leaving `IDLE`, the design uses the stored address.

---

### Parameterized Widths

The fixed implementation originally used fixed coordinate widths.

The parameterized baseline instead calculates coordinate widths using `$clog2`, with a minimum width of one bit for dimensions of size 1.

---

### Division and Modulo Cost

The original parameterized design reconstructs coordinates using `/` and `%`.

Synthesis showed that arbitrary non-power-of-two divisors can produce substantial logic.

The reduced-arithmetic and comparison-only versions were developed to investigate this cost.

The synthesis results showed that eliminating arithmetic entirely is highly effective for small fixed dimensions, but generated comparison logic eventually scales beyond the arithmetic alternatives.

---

## Repository Structure

```text
.
├── rtl/
│   ├── prefetcher_3d.sv
│   ├── prefetcher_3d_reduced.sv
│   └── prefetcher_3d_compare.sv
│
├── sim/
│   ├── tb_prefetcher_3d.sv
│   ├── tb_prefetcher_3d_reduced.sv
│   ├── tb_prefetcher_3d_compare.sv
│   └── Makefile
│
├── synth/
│   ├── run_synth.sh
│   ├── run_synth_large.sh
│   ├── run_synth_crossover.sh
│   ├── results/
│   ├── results_large/
│   └── results_crossover/
│
└── docs/
    ├── notes_parameterized.md
    ├── notes_optimization.md
    └── screenshots/
```

The original fixed `3 x 3 x 3` implementation may also be retained in the repository for historical reference.

---

## Simulation

Simulation is performed using Verilator.

The testbenches are located in:

```text
sim/
```

The three implementations have separate testbenches:

```text
tb_prefetcher_3d.sv
tb_prefetcher_3d_reduced.sv
tb_prefetcher_3d_compare.sv
```

From the `sim` directory, use the Makefile to build and run the desired simulation.

Generated VCD waveforms can be inspected using GTKWave.

For example:

```bash
gtkwave waveform.vcd
```

---

## Synthesis Scripts

The synthesis experiments are located in:

```text
synth/
```

The scripts are separated by purpose:

```text
run_synth.sh
```

runs the original set of representative configurations.

```text
run_synth_large.sh
```

runs larger cube configurations to study scaling.

```text
run_synth_crossover.sh
```

runs configurations around the crossover region to identify when the comparison-only implementation becomes larger than the arithmetic implementations.

---

## Final Result

The project now contains three functionally equivalent implementations of a parameterized 3D spatial prefetcher.

All versions:

- support arbitrary positive `X_SIZE x Y_SIZE x Z_SIZE` dimensions
- use flattened 3D address mapping
- output one valid adjacent address per clock cycle
- skip invalid directions without inserting unnecessary output gaps
- store the active request internally
- support dimensions of size 1
- reject out-of-range addresses
- preserve the same external interface and output behavior

The implementations differ in how they determine boundary validity:

- **Baseline:** reconstructs coordinates using division and modulo.
- **Reduced-arithmetic:** removes division and uses two modulo operations.
- **Comparison-only:** removes division and modulo entirely.

Synthesis showed that there is no single implementation that is smallest for every parameter configuration.

For small arbitrary grids, the comparison-only implementation can be dramatically smaller.

For larger arbitrary dimensions, the reduced-arithmetic implementation scales better.

For power-of-two dimensions, the baseline can synthesize especially efficiently because division and modulo reduce to simple binary operations.

The project therefore demonstrates both the functional design of a parameterized spatial prefetcher and the hardware tradeoffs introduced by different methods of mapping a flattened address back to 3D boundaries.
