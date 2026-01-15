(* Generate Verilog *)

open Stdio
open Hardcaml

module Dial = Day01.Dial_solver

let () =
  let module Circuit = Circuit.With_interface(Dial.I)(Dial.O) in
  let circuit = Circuit.create_exn ~name:"dial_solver" Dial.create in
  Rtl.output ~output_mode:(To_file "dial_solver.v") Verilog circuit;
  printf "wrote dial_solver.v\n"