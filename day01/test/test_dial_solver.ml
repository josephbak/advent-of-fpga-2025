(* Testbench for Day 1: Safe Dial *)

open Base
open Stdio
open Hardcaml

module Dial = Day01.Dial_solver
module Sim = Cyclesim.With_interface(Dial.I)(Dial.O)

let parse_rotation s =
  let dir = Char.equal (String.get s 0) 'R' in
  let dist = Int.of_string (String.sub s ~pos:1 ~len:(String.length s - 1)) in
  (dir, dist)

let run_test rotations =
  let sim = Sim.create Dial.create in
  let i = Cyclesim.inputs sim in
  let o = Cyclesim.outputs sim in
  
  (* reset *)
  i.clear := Bits.vdd;
  Cyclesim.cycle sim;
  i.clear := Bits.gnd;
  Cyclesim.cycle sim;
  
  printf "Initial position: %d\n" (Bits.to_int !(o.position));
  
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
  
  let p1 = Bits.to_int !(o.part1_count) in
  let p2 = Bits.to_int !(o.part2_count) in
  printf "\nPart 1: %d\nPart 2: %d\n" p1 p2;
  (p1, p2)

let test_simple () =
  printf "\n-- simple movements --\n";
  let rotations = ["R50"; "R100"; "L50"; "R150"] in
  let (p1, p2) = run_test rotations in
  assert (p1 = 3);
  assert (p2 = 4)

let test_r1000 () =
  printf "\n-- R1000 wraparound --\n";
  let (p1, p2) = run_test ["R1000"] in
  assert (p1 = 0);
  assert (p2 = 10)

let test_left () =
  printf "\n-- left movements --\n";
  let rotations = ["L50"; "L100"; "L49"] in
  let (p1, p2) = run_test rotations in
  assert (p1 = 2);
  assert (p2 = 2)

let test_edge_cases () =
  printf "\n-- edge cases (never hit zero) --\n";
  let rotations = ["R1"; "L1"; "R49"; "L49"] in
  let (p1, p2) = run_test rotations in
  assert (p1 = 0);
  assert (p2 = 0)

let () =
  printf "Day 1 testbench\n";
  test_simple ();
  test_r1000 ();
  test_left ();
  test_edge_cases ();
  printf "\nall passed\n"