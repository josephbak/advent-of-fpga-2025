(* Day 1: Safe Dial *)

open Base
open Hardcaml
open Signal

module I = struct
  type 'a t = {
    clock : 'a;
    clear : 'a;
    direction : 'a;           (* 0=left, 1=right *)
    distance : 'a; [@bits 16]
    valid : 'a;
  }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t = {
    position : 'a; [@bits 7]
    part1_count : 'a; [@bits 32]
    part2_count : 'a; [@bits 32]
  }
  [@@deriving hardcaml]
end

(* Hardware dividers are slow/expensive. Use reciprocal multiplication instead:
   x/100 = (x * 5243) >> 19, where 5243 ≈ 2^19/100
   Works exactly for x in 0..65535 *)
let div_100 x =
  let magic = of_int ~width:32 5243 in
  let prod = uresize x 32 *: magic in
  sel_bottom (srl prod 19) 16

let mod_100 x =
  let q = uresize (div_100 x) 32 in
  let hundred = of_int ~width:32 100 in
  let prod = sel_bottom (q *: hundred) 32 in
  sel_bottom (uresize x 32 -: prod) 7

let compute_rotation ~pos ~dist ~dir =
  let p = uresize pos 32 in
  let d = uresize dist 32 in
  let hundred = of_int ~width:32 100 in
  
  (* new position *)
  let rpos = mod_100 (p +: d) in
  let lpos = mod_100 (p +: hundred -: uresize (mod_100 d) 32) in
  let new_pos = mux2 dir rpos lpos in
  
  (* crossing count *)
  let rcross = uresize (div_100 (p +: d)) 32 in
  let offset = mux2 (pos ==: of_int ~width:7 0) (of_int ~width:32 0) (hundred -: p) in
  let lcross = uresize (div_100 (d +: offset)) 32 in
  let crossings = mux2 dir rcross lcross in
  
  (new_pos, crossings)

let create (i : _ I.t) =
  let spec = Reg_spec.create ~clock:i.clock () in
  
  let pos_reg = Always.Variable.reg spec ~enable:vdd ~width:7 in
  let p1_reg = Always.Variable.reg spec ~enable:vdd ~width:32 in
  let p2_reg = Always.Variable.reg spec ~enable:vdd ~width:32 in
  
  let pos = Always.Variable.value pos_reg in
  let p1 = Always.Variable.value p1_reg in
  let p2 = Always.Variable.value p2_reg in
  
  let (new_pos, crossings) = compute_rotation ~pos ~dist:i.distance ~dir:i.direction in
  let lands_on_zero = new_pos ==: of_int ~width:7 0 in
  
  Always.(compile [
    if_ i.clear [
      pos_reg <-- of_int ~width:7 50;
      p1_reg <-- of_int ~width:32 0;
      p2_reg <-- of_int ~width:32 0;
    ] @@ elif i.valid [
      pos_reg <-- new_pos;
      p1_reg <-- p1 +: mux2 lands_on_zero (of_int ~width:32 1) (of_int ~width:32 0);
      p2_reg <-- p2 +: crossings;
    ] []
  ]);
  
  { O.position = pos; part1_count = p1; part2_count = p2 }