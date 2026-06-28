(* ::Package:: *)
(* wolframClass — a reproducible, in-kernel *operational* classifier for the
   Wolfram class (1-4) of an elementary cellular automaton, computed from
   random initial conditions.

   It is a PROXY for Wolfram's qualitative visual classification, validated on
   27 literature-consensus anchor rules (100% agreement). Class 3 vs 4 is NOT
   reliably auto-separable; the four canonical class-4 rules {110,124,137,193}
   are applied as an explicit override.

   Method (per rule):
     - evolve a width-W random IC for T steps; also evolve a 1-cell-perturbed
       copy. The Hamming fraction of the difference in the late rows ("damage")
       is the order/chaos discriminator (averaged as a max over several seeds,
       so seed-sensitive rules like 18 are caught).
     - Class 1: late state uniform / zero per-row entropy (dies to homogeneity).
     - Class 2: settles to a small temporal period, or damage stays a thin front.
     - Class 3: damage fills its cone (Hamming fraction >= 0.04) AND late rows
       are spatially disordered (mean per-row entropy >= 0.5).
     - Class 4: override set {110,124,137,193}.

   Factored out of research/mass-dimension-wolfram-class (dimension-vs-class sweep).

   Usage:
     wolframClass[30]              -> 3
     wolframClass[110]             -> 4
     wolframClassData[18]          -> <|"ham"->..,"ent"->..,"per"->..,"class"->3|>
     wolframClass[r, W, T, seeds]  -> override the lattice/time/seed list
*)

wolframClass`smallPeriod[block_, pmax_:50] :=
  SelectFirst[Range[1, pmax],
    (block[[-1]] === block[[-1 - #]]) && (block[[-2]] === block[[-2 - #]]) &, 0];

wolframClass`class4set = {110, 124, 137, 193};

wolframClassData[rule_Integer, W_:401, T_:240, seeds_:{11, 29, 53}] :=
 Module[{hamfracs, ic, ic2, e1, e2, diff, fin, dens, perRow, uniform, per, hamfrac, c},
  hamfracs = Table[
     SeedRandom[s + rule];
     ic = RandomInteger[1, W]; ic2 = ic;
     ic2[[Ceiling[W/2]]] = 1 - ic2[[Ceiling[W/2]]];
     e1 = CellularAutomaton[rule, ic, T];
     e2 = CellularAutomaton[rule, ic2, T];
     diff = BitXor[e1, e2];
     N@Mean[Take[Total /@ diff, -60]]/W, {s, seeds}];
  hamfrac = Max[hamfracs];
  SeedRandom[First[seeds] + rule];
  ic = RandomInteger[1, W]; e1 = CellularAutomaton[rule, ic, T];
  fin = Take[e1, -80]; dens = N@Mean[Flatten[fin]];
  perRow = N@Mean[Entropy[2, #] & /@ Take[fin, -50]];
  uniform = (Length@Union[Flatten[Take[fin, -50]]] == 1) || perRow < 0.02;
  per = wolframClass`smallPeriod[fin, 50];
  c = Which[
    MemberQ[wolframClass`class4set, rule], 4,
    uniform, 1,
    hamfrac >= 0.04 && perRow >= 0.5, 3,
    per > 0, 2,
    hamfrac < 0.04, 2,
    True, 3];
  <|"ham" -> Round[hamfrac, 0.001], "dens" -> Round[dens, 0.01],
    "ent" -> Round[perRow, 0.01], "per" -> per, "class" -> c|>];

wolframClass[rule_Integer, args___] := wolframClassData[rule, args]["class"];
