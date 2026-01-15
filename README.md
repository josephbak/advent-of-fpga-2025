# Advent of FPGA 2025

My submission for the [Jane Street Advent of FPGA Challenge](https://blog.janestreet.com/advent-of-fpga-challenge-2025/).

This was my first time using OCaml or Hardcaml. I've been learning about compilers and wanted to try something on the hardware side. Hardcaml caught my attention because it's basically "code that builds circuits" — similar vibe to the MLIR stuff I've been studying.

Only had time for Day 1, but it was a good exercise in thinking about hardware constraints vs just writing an algorithm.

## Running it
```bash
cd day01
opam install hardcaml ppx_hardcaml base stdio
dune build
dune exec test/test_dial_solver.exe
dune exec bin/main.exe  # generates Verilog
```

Joseph Bak