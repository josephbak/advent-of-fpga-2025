# Day 1: Safe Dial

Dial goes 0-99 in a circle, starts at 50. You get rotation commands like `L68` (left 68 steps) or `R48` (right 48). It wraps around.

- Part 1: how many times do we land exactly on 0?
- Part 2: how many times do we pass through 0 (including landing)?

The tricky bit: `R1000` from position 50 wraps around 10 times and ends back at 50.

## Files

- `lib/dial_solver.ml` — the circuit
- `test/test_dial_solver.ml` — simulation tests
- `bin/main.ml` — generates Verilog
- `bin/solve.ml` — runs circuit on an input file

## The approach

Hardware dividers are expensive, so I used the reciprocal multiplication trick:
```
x / 100 = (x * 5243) >> 19
```

This works because 5243 ≈ 2^19 / 100. Multipliers are cheap on FPGAs (dedicated DSP blocks), and the shift is free — just wire routing.

For counting crossings:
- Going right from pos by dist: `crossings = (pos + dist) / 100`
- Going left: need to account for where 0 sits relative to current position

Everything runs in one clock cycle per command.

## What I'd do differently

If I had more time:
- Pipeline the multipliers for higher clock speeds
- Share one multiplier across uses (trade area for latency)

But for a first Hardcaml project, keeping it simple felt right.

## Build & test
```bash
dune build
dune exec test/test_dial_solver.exe
dune exec bin/main.exe  # outputs dial_solver.v
dune exec bin/solve.exe -- input.txt  # run on actual input
```

Joseph Bak