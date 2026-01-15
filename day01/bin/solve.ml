(* Run the circuit on an input file *)

open Base
open Stdio
open Hardcaml

module Dial = Day01.Dial_solver
module Sim = Cyclesim.With_interface(Dial.I)(Dial.O)

let parse_rotation s =
  let s = String.strip s in
  if String.is_empty s then None
  else
    let dir = Char.equal (String.get s 0) 'R' in
    let dist = Int.of_string (String.sub s ~pos:1 ~len:(String.length s - 1)) in
    Some (dir, dist)

let process_input filename =
  let sim = Sim.create Dial.create in
  let i = Cyclesim.inputs sim in
  let o = Cyclesim.outputs sim in
  
  i.clear := Bits.vdd;
  Cyclesim.cycle sim;
  i.clear := Bits.gnd;
  Cyclesim.cycle sim;
  
  let input = In_channel.read_all filename in
  let tokens = 
    input 
    |> String.substr_replace_all ~pattern:"\n" ~with_:" "
    |> String.split ~on:' '
    |> List.filter ~f:(fun s -> not (String.is_empty (String.strip s)))
  in
  
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
  (Bits.to_int !(o.part1_count), Bits.to_int !(o.part2_count))

let () =
  let args = Sys.get_argv () in
  if Array.length args < 2 then (
    eprintf "usage: %s <input_file>\n" args.(0);
    Stdlib.exit 1
  );
  
  let filename = args.(1) in
  if not (Stdlib.Sys.file_exists filename) then (
    eprintf "file not found: %s\n" filename;
    Stdlib.exit 1
  );
  
  let (p1, p2) = process_input filename in
  printf "Part 1: %d\nPart 2: %d\n" p1 p2