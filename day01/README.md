# AoC 2025 Day 1: Safe Dial - Hardcaml Implementation

Solution for [Advent of Code 2025 Day 1](https://adventofcode.com/2025/day/1) implemented in Hardcaml for the Jane Street FPGA Challenge.

## Problem Summary

- **Dial**: Circular positions 0-99, starts at 50
- **Input**: Sequence of rotations like `L68`, `R48` (Left/Right + distance)
- **Wraparound**: Left from 0 → 99, Right from 99 → 0
- **Part 1**: Count times the dial **ends** on position 0
- **Part 2**: Count times the dial **passes through or lands** on position 0 (including during rotation)

### Edge Case
`R1000` from position 50 crosses 0 exactly **10 times** and ends at 50.

## Circuit Architecture

```
                        ┌─────────────────────────────────────┐
  direction (1b) ──────►│                                     │
  distance (16b) ──────►│  Combinational Logic                │
                        │  ┌──────────┐  ┌──────────┐         │
  position ────────────►│  │ div_100  │  │ mod_100  │         │
                        │  └──────────┘  └──────────┘         │
                        │        │              │             │
                        │        ▼              ▼             │
                        │   crossings      new_position       │──► position_reg
                        │        │              │             │
                        └────────┼──────────────┼─────────────┘
                                 │              │
                                 ▼              ▼
                           part2_reg       part1_reg (if new_pos == 0)
```

### Key Implementation Details

**Division by 100** (constant divisor optimization):
```
div_100(x) = (x × 5243) >> 19
```
This uses the "magic number" multiplication trick. Valid for x ∈ [0, 65535].

**Crossing Count Formulas**:
- **Right**: `crossings = ⌊(pos + dist) / 100⌋`
- **Left**: `crossings = ⌊(dist + offset) / 100⌋` where `offset = 0` if `pos=0`, else `100-pos`

## Project Structure

```
aoc_day1_hardcaml/
├── lib/
│   ├── dial_solver.ml    # Main circuit implementation
│   └── dune
├── bin/
│   ├── main.ml           # Verilog generation
│   └── dune
├── test/
│   ├── test_dial_solver.ml  # Simulation testbench
│   └── dune
├── dune-project
└── README.md
```

## Building & Running

### Prerequisites
```bash
# Install opam and required packages
opam install hardcaml hardcaml_waveterm base stdio ppx_hardcaml
```

### Build
```bash
cd aoc_day1_hardcaml
dune build
```

### Run Tests
```bash
dune exec test/test_dial_solver.exe
```

Expected output:
```
========================================
AoC 2025 Day 1 - Hardcaml Testbench
========================================

=== Test: Simple movements ===
Initial position: 50
R50: pos=0, part1=1, part2=1
R100: pos=0, part1=2, part2=2
L50: pos=50, part1=2, part2=2
R150: pos=0, part1=3, part2=4
...
✓ All tests passed!
```

### Generate Verilog
```bash
dune exec bin/main.exe
# Creates dial_solver.v in current directory
```

## Interface

### Inputs
| Signal    | Width | Description |
|-----------|-------|-------------|
| `clock`   | 1     | Clock signal |
| `clear`   | 1     | Synchronous reset (initializes position to 50) |
| `direction` | 1   | 0 = Left, 1 = Right |
| `distance` | 16   | Rotation distance |
| `valid`   | 1     | Pulse high for one cycle per rotation |

### Outputs
| Signal       | Width | Description |
|--------------|-------|-------------|
| `position`   | 7     | Current dial position (0-99) |
| `part1_count` | 32   | Times ended on 0 |
| `part2_count` | 32   | Times passed through/landed on 0 |

## Processing Your AoC Input

To process your actual AoC input, modify `test_dial_solver.ml`:

```ocaml
let () =
  (* Parse your input file *)
  let input = In_channel.read_all "input.txt" in
  let rotations = String.split input ~on:' ' |> List.filter ~f:(fun s -> not (String.is_empty s)) in
  let (_, p1, p2) = run_test rotations in
  printf "Part 1: %d\n" p1;
  printf "Part 2: %d\n" p2
```

## Design Rationale

1. **Single-cycle processing**: Each rotation command is processed in one clock cycle
2. **Synthesizable arithmetic**: Division by 100 uses multiplier + shift instead of hardware divider
3. **Clean FSM**: Uses Hardcaml's `Always` DSL for readable sequential logic
4. **Parameterized widths**: Distance supports up to 65535, easily adjustable

## Author

Joseph Bak

## License

MIT
