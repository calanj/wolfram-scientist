(* ::Package:: *)
(* massDimension — mass (cluster) dimension of a cellular-automaton single-seed
   pattern. Counts live cells in the first s = 2^k rows and fits the slope of
   log2(mass) vs log2(s). More robust than box-counting for self-similar lattice
   fractals: returns log2(3) to ~14 digits for rule 90.

   Factored out of research/eca-additivity-fractality.

   Usage:
     massDimension[90]      -> 1.5849625007211554   (* ~ log2 3 *)
     massDimension[30]      -> ~1.91                 (* near space-filling *)
     massDimension[rule, K] -> use 2^K rows (default K = 9)
*)

massDimension[rule_Integer, K_Integer: 9] := Module[{m, sizes, mass, data},
   m = CellularAutomaton[rule, {{1}, 0}, 2^K];
   sizes = 2^Range[2, K];
   mass = (Total[Flatten[Take[m, #]]]) & /@ sizes;
   data = Transpose[{Log2[sizes], Log2[N[mass /. 0 -> 1]]}];
   Last@LinearModelFit[data, x, x]["BestFitParameters"]
   ];
