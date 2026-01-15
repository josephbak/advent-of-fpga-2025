(** AoC 2025 Day 1: Safe Dial - Hardcaml Implementation
    
    Dial: positions 0-99, starts at 50
    Input: sequence of rotations (L/R + distance)
    Part 1: Count times dial ENDS on 0 after a rotation
    Part 2: Count times dial PASSES THROUGH or lands on 0
*)

open Base
open Hardcaml
open Signal

module I = struct
  type 'a t = {
    clock : 'a;
    clear : 'a;               (** Synchronous reset *)
    direction : 'a;           (** 0 = Left, 1 = Right *)
    distance : 'a; [@bits 16] (** Rotation distance *)
    valid : 'a;               (** High for one cycle per rotation command *)
  }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t = {
    position : 'a; [@bits 7]      (** Current dial position (0-99) *)
    part1_count : 'a; [@bits 32]  (** Times ended on 0 *)
    part2_count : 'a; [@bits 32]  (** Times passed through or landed on 0 *)
  }
  [@@deriving hardcaml]
end

(** Division by 100 using magic number multiplication.
    
    For constant divisor d=100, k=19: m = ceil(2^19/100) = 5243
    x/100 ≈ (x * 5243) >> 19
    Valid for x in [0, 65535]
*)
let div_100 x =
  let magic = of_int ~width:32 5243 in
  let product = uresize x 32 *: magic in
  sel_bottom (srl product 19) 16

(** x mod 100 = x - (x/100) * 100 *)
let mod_100 x =
  let quotient = uresize (div_100 x) 32 in
  let hundred = of_int ~width:32 100 in
  let x_ext = uresize x 32 in
  let product = sel_bottom (quotient *: hundred) 32 in
  sel_bottom (x_ext -: product) 7

(** Compute new position and crossing count *)
let compute_rotation ~pos ~dist ~dir =
  let pos_32 = uresize pos 32 in
  let dist_32 = uresize dist 32 in
  let hundred = of_int ~width:32 100 in
  let zero_7 = of_int ~width:7 0 in
  
  (* NEW POSITION *)
  (* Right: (pos + dist) mod 100 *)
  let right_new_pos = mod_100 (pos_32 +: dist_32) in
  
  (* Left: (pos + 100 - (dist mod 100)) mod 100 *)
  let dist_mod_100 = mod_100 dist_32 in
  let left_temp = pos_32 +: hundred -: uresize dist_mod_100 32 in
  let left_new_pos = mod_100 left_temp in
  
  let new_pos = mux2 dir right_new_pos left_new_pos in
  
  (* CROSSING COUNT *)
  (* Right: floor((pos + dist) / 100) *)
  let right_crossings = uresize (div_100 (pos_32 +: dist_32)) 32 in
  
  (* Left: floor((dist + offset) / 100) where offset = 0 if pos=0, else 100-pos *)
  let pos_is_zero = pos ==: zero_7 in
  let left_offset = mux2 pos_is_zero (of_int ~width:32 0) (hundred -: pos_32) in
  let left_crossings = uresize (div_100 (dist_32 +: left_offset)) 32 in
  
  let crossings = mux2 dir right_crossings left_crossings in
  
  (new_pos, crossings)

(** Main circuit *)
let create (i : _ I.t) =
  let spec = Reg_spec.create ~clock:i.clock () in
  let initial_pos = of_int ~width:7 50 in
  
  (* State registers using Always DSL *)
  let position_reg = Always.Variable.reg spec ~enable:vdd ~width:7 in
  let part1_reg = Always.Variable.reg spec ~enable:vdd ~width:32 in
  let part2_reg = Always.Variable.reg spec ~enable:vdd ~width:32 in
  
  let position = Always.Variable.value position_reg in
  let part1_count = Always.Variable.value part1_reg in
  let part2_count = Always.Variable.value part2_reg in
  
  (* Combinational: compute next state *)
  let (new_pos, crossings) = 
    compute_rotation ~pos:position ~dist:i.distance ~dir:i.direction 
  in
  let ends_on_zero = new_pos ==: of_int ~width:7 0 in
  let one = of_int ~width:32 1 in
  let zero = of_int ~width:32 0 in
  
  (* Sequential logic *)
  Always.(compile [
    if_ i.clear [
      position_reg <-- initial_pos;
      part1_reg <-- zero;
      part2_reg <-- zero;
    ] @@ elif i.valid [
      position_reg <-- new_pos;
      part1_reg <-- part1_count +: (mux2 ends_on_zero one zero);
      part2_reg <-- part2_count +: crossings;
    ] []
  ]);
  
  { O.position; part1_count; part2_count }
