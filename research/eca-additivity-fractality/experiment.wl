(* ::Package:: *)
(* Reproducible experiment: additivity vs. fractal dimension in elementary CAs.
   Run top-to-bottom in a fresh kernel:  wolframscript -file experiment.wl
   Every headline number in findings.md is produced here. *)

(* ---- 1. Additive (GF(2)-linear) elementary rules ---------------------- *)
neigh[n_] := IntegerDigits[n, 2, 3];
ruleNumberFromFunc[f_] := FromDigits[Table[f @@ neigh[n], {n, 7, 0, -1}], 2];
additive = Sort@DeleteDuplicates@Flatten@Table[
    ruleNumberFromFunc[Function[{p, q, r}, Mod[a p + b q + c r, 2]]],
    {a, 0, 1}, {b, 0, 1}, {c, 0, 1}];
affine = Sort@DeleteDuplicates@Flatten@Table[
    ruleNumberFromFunc[Function[{p, q, r}, Mod[a p + b q + c r + d, 2]]],
    {a, 0, 1}, {b, 0, 1}, {c, 0, 1}, {d, 0, 1}];
Print["Additive rules: ", additive];            (* {0,60,90,102,150,170,204,240} *)

(* ---- 2. Mass dimension from a single seed ----------------------------- *)
(* count live cells in the first s = 2^k rows; dimension = slope log2(mass) vs log2(s) *)
massDim[rule_, K_: 9] := Module[{m, sizes, mass, data},
   m = CellularAutomaton[rule, {{1}, 0}, 2^K];
   sizes = 2^Range[2, K];
   mass = (Total[Flatten[Take[m, #]]]) & /@ sizes;
   data = Transpose[{Log2[sizes], Log2[N[mass /. 0 -> 1]]}];
   Last@LinearModelFit[data, x, x]["BestFitParameters"]];

(* validation against closed forms *)
Print["rule 90 massDim = ", massDim[90], "  (theory log2 3 = ", N[Log2[3]], ")"];
Print["rule 204 (identity) = ", massDim[204], ";  rule 0 (null) = ", massDim[0]];

(* ---- 3. Full scan of all 256 rules ------------------------------------ *)
dims = AssociationMap[massDim[#] &, Range[0, 255]];

addDims = KeyTake[dims, additive];
Print["Additive-rule dimensions: ", addDims];

sierp = Log2[3];
nonAddFractal = Sort@Select[Complement[Range[0, 255], additive],
    Abs[dims[#] - sierp] < 0.03 &];
Print["Non-additive rules with dim ~ log2 3: ", nonAddFractal];

(* ---- 4. Refutation: WHY do non-additive rules hit log2 3? ------------- *)
(* (a) exactness: live-cell count is exactly 3^k, not approximately *)
massSeq[rule_, K_] := Table[Total@Flatten@Take[CellularAutomaton[rule, {{1}, 0}, 2^K], 2^k], {k, 1, K}];
Print["rule 18 mass sequence: ", massSeq[18, 8], "  vs 3^k: ", Table[3^k, {k, 8}]];

(* (b) which of them are literally rule-90 patterns on the single-seed orbit? *)
r90 = CellularAutomaton[90, {{1}, 0}, 64];
orbitEquiv = AssociationMap[(CellularAutomaton[#, {{1}, 0}, 64] === r90) &, nonAddFractal];
Print["Pattern identical to rule 90?  ", orbitEquiv];
outliers = Select[nonAddFractal, ! orbitEquiv[#] &];
Print["Non-additive, NOT orbit-equivalent to 90, yet dim = log2 3: ", outliers]; (* {22} *)

(* (c) stability of the estimate with resolution *)
Print["Stability {K, dim90, dim22}: ", Table[{K, massDim[90, K], massDim[22, K]}, {K, 6, 10}]];
