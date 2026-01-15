(** Generate Verilog output for AoC 2025 Day 1 *)

open Stdio
open Hardcaml

module Dial = Day01.Dial_solver

let () =
  let module Circuit = Circuit.With_interface(Dial.I)(Dial.O) in
  
  let circuit = Circuit.create_exn ~name:"dial_solver" Dial.create in
  
  (* Output Verilog to file *)
  Rtl.output ~output_mode:(To_file "dial_solver.v") Verilog circuit;
  printf "Generated dial_solver.v\n";
  
  (* Also output to stdout *)
  printf "\n=== Verilog Output ===\n";
  Rtl.output ~output_mode:(To_channel Stdio.stdout) Verilog circuit
