(** Testbench for AoC 2025 Day 1: Safe Dial *)

open Base
open Stdio
open Hardcaml

module Dial = Day01.Dial_solver
module Sim = Cyclesim.With_interface(Dial.I)(Dial.O)

(** Parse rotation string like "L68" or "R48" *)
let parse_rotation s =
  let dir = Char.equal (String.get s 0) 'R' in
  let dist = Int.of_string (String.sub s ~pos:1 ~len:(String.length s - 1)) in
  (dir, dist)

(** Run simulation with a list of rotations *)
let run_test rotations =
  let sim = Sim.create Dial.create in
  
  let i = Cyclesim.inputs sim in
  let o = Cyclesim.outputs sim in
  
  (* Initial reset *)
  i.clear := Bits.vdd;
  Cyclesim.cycle sim;
  i.clear := Bits.gnd;
  Cyclesim.cycle sim;
  
  printf "Initial position: %d\n" (Bits.to_int !(o.position));
  
  (* Apply each rotation *)
  List.iter rotations ~f:(fun rot_str ->
    let (dir, dist) = parse_rotation rot_str in
    i.direction := Bits.of_bool dir;
    i.distance := Bits.of_int ~width:16 dist;
    i.valid := Bits.vdd;
    Cyclesim.cycle sim;
    i.valid := Bits.gnd;
    
    printf "%s: pos=%d, part1=%d, part2=%d\n"
      rot_str
      (Bits.to_int !(o.position))
      (Bits.to_int !(o.part1_count))
      (Bits.to_int !(o.part2_count))
  );
  
  Cyclesim.cycle sim;
  
  let final_part1 = Bits.to_int !(o.part1_count) in
  let final_part2 = Bits.to_int !(o.part2_count) in
  
  printf "\n=== FINAL RESULTS ===\n";
  printf "Part 1 (ends on 0): %d\n" final_part1;
  printf "Part 2 (passes/lands on 0): %d\n" final_part2;
  
  (final_part1, final_part2)

(** Test case: simple crossings *)
let test_simple () =
  printf "\n=== Test: Simple movements ===\n";
  let rotations = [
    "R50";   (* 50 -> 0: ends on 0, 1 crossing *)
    "R100";  (* 0 -> 0: ends on 0, 1 crossing *)
    "L50";   (* 0 -> 50: no crossing *)
    "R150";  (* 50 -> 0: ends on 0, 2 crossings (at 50 and 150) *)
  ] in
  let (p1, p2) = run_test rotations in
  printf "Expected: Part1=3, Part2=4\n";
  printf "Got:      Part1=%d, Part2=%d\n" p1 p2;
  assert (p1 = 3);
  assert (p2 = 4)

(** Test case: R1000 from 50 crosses 0 ten times *)
let test_r1000 () =
  printf "\n=== Test: R1000 from position 50 ===\n";
  let rotations = ["R1000"] in
  let (p1, p2) = run_test rotations in
  (* R1000 from 50: ends at 50, crosses 0 exactly 10 times *)
  printf "Expected: Part1=0, Part2=10\n";
  printf "Got:      Part1=%d, Part2=%d\n" p1 p2;
  assert (p1 = 0);
  assert (p2 = 10)

(** Test case: left movements *)
let test_left () =
  printf "\n=== Test: Left movements ===\n";
  let rotations = [
    "L50";   (* 50 -> 0: ends on 0, crosses at step 50 *)
    "L100";  (* 0 -> 0: ends on 0, crosses at step 100 *)
    "L49";   (* 0 -> 51: no crossing *)
  ] in
  let (p1, p2) = run_test rotations in
  printf "Expected: Part1=2, Part2=2\n";
  printf "Got:      Part1=%d, Part2=%d\n" p1 p2;
  assert (p1 = 2);
  assert (p2 = 2)

(** Test case: edge cases *)
let test_edge_cases () =
  printf "\n=== Test: Edge cases ===\n";
  (* Start at 50, R1 -> 51, L1 -> 50, ... never hit 0 *)
  let rotations = ["R1"; "L1"; "R49"; "L49"] in
  let (p1, p2) = run_test rotations in
  printf "Expected: Part1=0, Part2=0\n";
  printf "Got:      Part1=%d, Part2=%d\n" p1 p2;
  assert (p1 = 0);
  assert (p2 = 0)

(** Test with AoC-style sample input *)
let test_aoc_sample () =
  printf "\n=== Test: AoC-style sample ===\n";
  (* Example: if input is "L68 R48 R52 L100 R1000" *)
  let rotations = ["L68"; "R48"; "R52"; "L100"; "R1000"] in
  let (p1, p2) = run_test rotations in
  printf "Part1=%d, Part2=%d\n" p1 p2

let () =
  printf "========================================\n";
  printf "AoC 2025 Day 1 - Hardcaml Testbench\n";
  printf "========================================\n";
  
  test_simple ();
  test_r1000 ();
  test_left ();
  test_edge_cases ();
  test_aoc_sample ();
  
  printf "\n✓ All tests passed!\n"
