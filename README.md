# Advent of FPGA 2025

My solutions to the [Jane Street Advent of FPGA Challenge 2025](https://www.janestreet.com/puzzles/advent-of-fpga-2025/) implemented in [Hardcaml](https://github.com/janestreet/hardcaml).

## Solutions

| Day | Problem | Status | Description |
|-----|---------|--------|-------------|
| 01  | Safe Dial | ✅ | Circular dial position tracking with zero-crossing detection |

## Project Structure

```
advent-of-fpga-2025/
├── day01/           # Each day is a self-contained dune project
│   ├── lib/         # Circuit implementation
│   ├── bin/         # Verilog generation & input solver
│   └── test/        # Simulation testbench
└── README.md
```

## Building & Running

Each day is an independent dune project:

```bash
cd day01
opam install hardcaml ppx_hardcaml base stdio
dune build
dune exec test/test_dial_solver.exe   # Run tests
dune exec bin/main.exe                 # Generate Verilog
```

## Design Philosophy

- **Single-cycle processing**: Each input command processed in one clock cycle
- **Synthesizable arithmetic**: Avoid hardware dividers; use multiplier tricks for constant division
- **Clean interfaces**: Hardcaml's `[@@deriving hardcaml]` for type-safe I/O
- **Testable**: Cycle-accurate simulation with assertion-based verification

## Author

Joseph Bak

## License

MIT
