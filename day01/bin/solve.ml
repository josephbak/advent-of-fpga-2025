(** Process actual AoC Day 1 input file *)

open Base
open Stdio
open Hardcaml

module Dial = Day01.Dial_solver
module Sim = Cyclesim.With_interface(Dial.I)(Dial.O)

(** Parse a single rotation string like "L68" or "R48" *)
let parse_rotation s =
  let s = String.strip s in
  if String.is_empty s then None
  else
    let dir = Char.equal (String.get s 0) 'R' in
    let dist = Int.of_string (String.sub s ~pos:1 ~len:(String.length s - 1)) in
    Some (dir, dist)

(** Process input file and return (part1, part2) results *)
let process_input filename =
  let sim = Sim.create Dial.create in
  let i = Cyclesim.inputs sim in
  let o = Cyclesim.outputs sim in
  
  (* Reset *)
  i.clear := Bits.vdd;
  Cyclesim.cycle sim;
  i.clear := Bits.gnd;
  Cyclesim.cycle sim;
  
  (* Read and parse input *)
  let input = In_channel.read_all filename in
  
  (* Handle both space-separated and newline-separated formats *)
  let tokens = 
    input 
    |> String.substr_replace_all ~pattern:"\n" ~with_:" "
    |> String.split ~on:' '
    |> List.filter ~f:(fun s -> not (String.is_empty (String.strip s)))
  in
  
  (* Process each rotation *)
  List.iter tokens ~f:(fun rot_str ->
    match parse_rotation rot_str with
    | None -> ()
    | Some (dir, dist) ->
      i.direction := Bits.of_bool dir;
      i.distance := Bits.of_int ~width:16 dist;
      i.valid := Bits.vdd;
      Cyclesim.cycle sim;
      i.valid := Bits.gnd
  );
  
  Cyclesim.cycle sim;
  
  let part1 = Bits.to_int !(o.part1_count) in
  let part2 = Bits.to_int !(o.part2_count) in
  
  (part1, part2)

let () =
  let args = Sys.get_argv () in
  if Array.length args < 2 then begin
    eprintf "Usage: %s <input_file>\n" args.(0);
    eprintf "Example: %s input.txt\n" args.(0);
    Stdlib.exit 1
  end;
  
  let filename = args.(1) in
  
  if not (Stdlib.Sys.file_exists filename) then begin
    eprintf "Error: File '%s' not found\n" filename;
    Stdlib.exit 1
  end;
  
  printf "Processing %s...\n" filename;
  let (part1, part2) = process_input filename in
  
  printf "\n=== AoC 2025 Day 1 Results ===\n";
  printf "Part 1: %d\n" part1;
  printf "Part 2: %d\n" part2
