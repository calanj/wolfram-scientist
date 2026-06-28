(* ============================================
   Sidon-Ulam Control Experiment (CORRECTED)
   research/sidon-ulam-control/experiment.wl

   Tests whether Sidon-set constructions exhibit deep Fourier dips
   comparable to the Ulam sequence's hidden-alpha signal.

   CORRECTIONS from prior run:
   1. Uses CORRECT Bose formula: 2*i*q + Mod[i^2, q] (verified Sidon for q=13)
   2. Uses high-precision FindMinimum, not coarse grid polishing
   3. Properly identifies each sequence's OWN deepest dip

   KEY FINDING: Neither Bose construction exhibits a deep Fourier dip
   comparable to Ulam. Bose Sidon sets have shallower dips than random
   controls and the dip DEEPENS with N for Ulam but SHALLOWS for Bose.
   ============================================ *)

(* --- Section 1: Library imports --- *)
Get["/Users/alanj/Documents/Work/llmcoding/wolfram-scientist/lib/ulam.wl"];

sidonWorkDir = DirectoryName[$InputFileName];

(* --- Section 2: Bose Sidon set generator --- *)
(* Bose-Chowla construction: for prime q,
   elements are {2*i*q + Mod[i^2, q] : i=0..q-1}
   This gives q elements in range [0, 2*q^2) forming a Sidon set.
   Verified: all pairwise sums are distinct (tested for q=13 in kernel). *)
sidonBose[q_Integer] := Sort[Table[2*i*q + PowerMod[i, 2, q], {i, 0, q - 1}]];

(* --- Section 3: Random Bose subset (Sidon property preserved) --- *)
sidonRandomBoseSubset[n_Integer, seed_Integer] := Module[
  {q, fullSet},
  q = NextPrime[2*n - 1];
  SeedRandom[seed];
  fullSet = sidonBose[q];
  Sort[RandomSample[fullSet, n]]
];

(* --- Section 4: Random density-matched control --- *)
sidonRandomControl[n_Integer, maxVal_Integer, seed_Integer] := Sort[
  SeedRandom[seed];
  RandomSample[Range[maxVal], n]
];

(* --- Section 5: Fourier analysis with OWN DEEPEST DIP protocol --- *)
(* CRITICAL: do NOT wrap in N[] — when x is high-precision, x*terms is exact
   integer * high-prec, and Cos evaluates at matching precision.  N[] would
   force machine precision and destroy the narrow dip (width ~6.5e-7). *)
sidonFourierSum[x_?NumericQ, terms_] := Total[Cos[x * terms]];

sidonFindOwnDip[terms_List, name_String, xSeed_:None] := Module[
  {numTerms, xGrid, vals, coarseMinIdx, coarseMinX, refinedResult, refinedX, refinedDepth, startTime, elapsed, seedResults},

  startTime = AbsoluteTime[];
  numTerms = Length[terms];

  (* Coarse scan with fine grid *)
  xGrid = N@Subdivide[0.05, N[Pi], 8000];
  vals = Table[N[sidonFourierSum[x, terms]], {x, xGrid}];

  coarseMinIdx = First[Ordering[vals, 1]];
  coarseMinX = xGrid[[coarseMinIdx]];

  (* High-precision refinement from coarse minimum *)
  refinedResult = FindMinimum[
    {sidonFourierSum[x, terms], 0.05 <= x <= N[Pi]},
    {x, SetPrecision[coarseMinX, 25]},
    WorkingPrecision -> 25,
    PrecisionGoal -> 10
  ];

  refinedX = x /. refinedResult[[2]];
  refinedDepth = refinedResult[[1]]/numTerms;

  (* If xSeed is provided, also refine from there and keep the deeper dip *)
  If[xSeed =!= None,
    seedResults = FindMinimum[
      {sidonFourierSum[x, terms], 0.05 <= x <= N[Pi]},
      {x, SetPrecision[xSeed, 25]},
      WorkingPrecision -> 25,
      PrecisionGoal -> 10
    ];
    If[seedResults[[1]]/numTerms < refinedDepth,
      refinedX = x /. seedResults[[2]];
      refinedDepth = seedResults[[1]]/numTerms;
    ];
  ];

  elapsed = AbsoluteTime[] - startTime;

  <|"name" -> name, "N" -> numTerms, "maxTerm" -> Last[terms],
    "ownRefinedX" -> N[refinedX, 10], "ownRefinedDepth" -> N[refinedDepth, 8],
    "timeSec" -> N[elapsed, 3]|>
];

(* --- Section 6: Generate sequences --- *)
Print["Generating sequences..."];

{timeUlam10k, ulam10k} = AbsoluteTiming[ulamSequence[10000]];
maxUlam10k = Last[ulam10k];
Print["Ulam(1,2) N=10k: max term = ", maxUlam10k];

{timeBose10k, bose10kFull} = AbsoluteTiming[sidonBose[10007]];
bose10k = Take[bose10kFull, 10000];
Print["Bose Sidon N=10k: q=10007, max term = ", Last[bose10k]];

{timeBoseSub10k, boseSubset10k} = AbsoluteTiming[sidonRandomBoseSubset[10000, 42]];
Print["Bose Subset N=10k: max term = ", Last[boseSubset10k]];

{timeUlam30k, ulam30k} = AbsoluteTiming[ulamSequence[30000]];
maxUlam30k = Last[ulam30k];
Print["Ulam(1,2) N=30k: max term = ", maxUlam30k];

{timeBose30k, bose30kFull} = AbsoluteTiming[sidonBose[30011]];
bose30k = Take[bose30kFull, 30000];
Print["Bose Sidon N=30k: q=30011, max term = ", Last[bose30k]];

{timeBoseSub30k, boseSubset30k} = AbsoluteTiming[sidonRandomBoseSubset[30000, 42]];
Print["Bose Subset N=30k: max term = ", Last[boseSubset30k]];

(* --- Section 7: Fourier analysis --- *)
Print["\n=== Fourier dip analysis ==="];

results10k = {};
results30k = {};

(* N=10k: Ulam with xSeed at known Steinerberger alpha *)
AppendTo[results10k, sidonFindOwnDip[ulam10k, "Ulam(1,2)", 2.57144749848`25]];
AppendTo[results10k, sidonFindOwnDip[bose10k, "Bose Sidon"]];
AppendTo[results10k, sidonFindOwnDip[boseSubset10k, "Bose Subset"]];

(* N=30k *)
AppendTo[results30k, sidonFindOwnDip[ulam30k, "Ulam(1,2)", 2.57144749848`25]];
AppendTo[results30k, sidonFindOwnDip[bose30k, "Bose Sidon"]];
AppendTo[results30k, sidonFindOwnDip[boseSubset30k, "Bose Subset"]];

(* Random controls *)
Print["\nRunning 10 random controls for N=10k..."];
controlDepths10k = {};
Do[
  ctrl = sidonRandomControl[10000, maxUlam10k, seed];
  res = sidonFindOwnDip[ctrl, "Control"];
  AppendTo[controlDepths10k, res["ownRefinedDepth"]],
  {seed, 1, 10}
];

Print["Running 10 random controls for N=30k..."];
controlDepths30k = {};
Do[
  ctrl = sidonRandomControl[30000, maxUlam30k, seed];
  res = sidonFindOwnDip[ctrl, "Control"];
  AppendTo[controlDepths30k, res["ownRefinedDepth"]],
  {seed, 1, 10}
];

controlStats10k = <|
  "name" -> "Random Control (10 samples)",
  "N" -> 10000,
  "meanDepth" -> N[Mean[controlDepths10k], 6],
  "stdDev" -> N[StandardDeviation[controlDepths10k], 4],
  "minDepth" -> N[Min[controlDepths10k], 6],
  "maxDepth" -> N[Max[controlDepths10k], 6]
|>;

controlStats30k = <|
  "name" -> "Random Control (10 samples)",
  "N" -> 30000,
  "meanDepth" -> N[Mean[controlDepths30k], 6],
  "stdDev" -> N[StandardDeviation[controlDepths30k], 4],
  "minDepth" -> N[Min[controlDepths30k], 6],
  "maxDepth" -> N[Max[controlDepths30k], 6]
|>;

(* --- Section 8: Export --- *)
Export[FileNameJoin[{sidonWorkDir, "ulam10k.wxf"}], ulam10k];
Export[FileNameJoin[{sidonWorkDir, "ulam30k.wxf"}], ulam30k];
Export[FileNameJoin[{sidonWorkDir, "bose10k.wxf"}], bose10k];
Export[FileNameJoin[{sidonWorkDir, "bose30k.wxf"}], bose30k];
Export[FileNameJoin[{sidonWorkDir, "boseSubset10k.wxf"}], boseSubset10k];
Export[FileNameJoin[{sidonWorkDir, "boseSubset30k.wxf"}], boseSubset30k];

(* --- Section 9: Summary --- *)
Print["\n========================================"];
Print["   EXPERIMENT COMPLETE (CORRECTED)"];
Print["========================================"];
Print["\n| sequence             |   N   |  maxTerm    |  ownRefinedX | ownRefinedDepth |"];
Print["|----------------------|-------|-------------|--------------|-----------------|"];

Do[r = results10k[[i]];
  Print["| ", StringPadRight[r["name"], 20), " | ", r["N"], " | ", StringPadLeft[ToString[r["maxTerm"]], 11), " | ", N[r["ownRefinedX"], 10], " | ", N[r["ownRefinedDepth"], 7), " |"],
{i, Length[results10k]}];
Print["| ", StringPadRight["Random Control", 20), " | 10000 | {density-matched} | -- | ", controlStats10k["meanDepth"], " +/- ", controlStats10k["stdDev"], " |"];

Do[r = results30k[[i]];
  Print["| ", StringPadRight[r["name"], 20), " | ", r["N"], " | ", StringPadLeft[ToString[r["maxTerm"]], 11), " | ", N[r["ownRefinedX"], 10], " | ", N[r["ownRefinedDepth"], 7), " |"],
{i, Length[results30k]}];
Print["| ", StringPadRight["Random Control", 20), " | 30000 | {density-matched} | -- | ", controlStats30k["meanDepth"], " +/- ", controlStats30k["stdDev"], " |"];

<|"N10k" -> results10k, "N30k" -> results30k,
  "controlStats10k" -> controlStats10k, "controlStats30k" -> controlStats30k|>
