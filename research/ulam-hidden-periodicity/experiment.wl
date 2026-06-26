(* === Experiment 1: Ulam generator + Fourier signal === *)
(* Date: 2026-06-25 *)
(* Target: generate 100000 Ulam terms, scan Fourier sum, find alpha hat, exceptional set *)

SetDirectory[DirectoryName[$InputFileName]];

(* ---------------------------------------------------- *)
(* 1. Compiled Ulam generator (Gibbs counter-based sieve) *)
(* ---------------------------------------------------- *)
GenerateUlamCompiled = Compile[{{nTerms, _Integer}, {maxCount, _Integer}},
  Module[
    {terms, count, last, next, currentN, i, j},
    terms = Table[0, {nTerms}];
    count = Table[0, {maxCount}];
    terms[[1]] = 1;
    terms[[2]] = 2;
    count[[3]] = 1;
    last = 2;
    currentN = 2;
    While[currentN < nTerms,
      next = last + 1;
      While[next <= maxCount && count[[next]] != 1,
        next++
      ];
      If[next > maxCount,
        Break[]
      ];
      currentN++;
      terms[[currentN]] = next;
      last = next;
      For[i = 1, i < currentN, i++,
        j = next + terms[[i]];
        If[j <= maxCount,
          count[[j]] = count[[j]] + 1
        ]
      ];
    ];
    terms
  ],
  CompilationTarget -> "C",
  RuntimeOptions -> "Speed"
];

GenerateUlam[nTerms_] := Module[
  {maxCount = Ceiling[nTerms/0.07] + 200000, terms},
  terms = GenerateUlamCompiled[nTerms, maxCount];
  If[terms[[-1]] == 0,
    (* maxCount was too small, retry with larger buffer *)
    maxCount = Ceiling[nTerms/0.07] + 500000;
    terms = GenerateUlamCompiled[nTerms, maxCount];
  ];
  terms
];

(* ---------------------------------------------------- *)
(* 2. Generate terms with timing constraint              *)
(* ---------------------------------------------------- *)
$N = 100000;
{genTime, ulamTerms} = AbsoluteTiming @ TimeConstrained[GenerateUlam[$N], 240, $Failed];
If[Head[ulamTerms] === List && Length[ulamTerms] == $N,
  Print["Generated ", $N, " terms in ", genTime, " s"];
  ,
  (* fallback *)
  $N = 50000;
  {genTime, ulamTerms} = AbsoluteTiming @ TimeConstrained[GenerateUlam[$N], 240, $Failed];
  Print["Falling back to N=", $N, "; generated in ", genTime, " s"];
];

(* Sanity check first 20 terms *)
knownPrefix = {1, 2, 3, 4, 6, 8, 11, 13, 16, 18, 26, 28, 36, 38, 47, 48, 53, 57, 62, 69};
If[Take[ulamTerms, 20] != knownPrefix,
  Print["ERROR: prefix mismatch!"];
  Print[Take[ulamTerms, 20]];
  Abort[]
];

maxTerm = ulamTerms[[-1]];
density = N[$N / maxTerm, 12];

Export["ulam_terms.wxf", ulamTerms];
Print["Saved ulam_terms.wxf"];

(* ---------------------------------------------------- *)
(* 3. Fourier sum definitions (packed / vectorised)      *)
(* ---------------------------------------------------- *)
$packedUlam = Developer`ToPackedArray[N[ulamTerms]];

FourierSum[x_?NumericQ] := Total[Cos[x * $packedUlam]];

FourierSumVector[xs_List] := Total[Cos[Outer[Times, Developer`ToPackedArray[N[xs]], $packedUlam, 1]], {2}];

(* ---------------------------------------------------- *)
(* 4. Coarse scan on [0.05, Pi] with 4000 points         *)
(* ---------------------------------------------------- *)
piVal = 3.141592653589793;
$coarseX = Developer`ToPackedArray[N[Subdivide[0.05, piVal, 3999]]];
{scanTime, coarseVals} = AbsoluteTiming @ TimeConstrained[
  FourierSumVector[$coarseX],
  120,
  $Failed
];
If[Head[coarseVals] === List,
  Print["Coarse scan (4000 pts) done in ", scanTime, " s"];
  , (* fallback *)
  $Ncoarse = 2000;
  $coarseX = Developer`ToPackedArray[N[Subdivide[0.05, piVal, $Ncoarse - 1]]];
  {scanTime, coarseVals} = AbsoluteTiming @ FourierSumVector[$coarseX];
  Print["Coarse scan fallback (", $Ncoarse, " pts) done in ", scanTime, " s"];
];

coarsePlot = ListLinePlot[Transpose[{$coarseX, coarseVals/$N}],
  PlotRange -> All, AxesLabel -> {"x", "f_N(x)/N"},
  ImageSize -> 600
];
Export["exp1_scan.png", coarsePlot];
Print["Saved exp1_scan.png"];

(* Deepest minimum in [2,3] *)
idx23 = Pick[Range[Length[$coarseX]], UnitStep[$coarseX - 2.0] * UnitStep[3.0 - $coarseX], 1];
If[Length[idx23] > 0,
  localIdx = idx23[[Position[coarseVals[[idx23]], Min[coarseVals[[idx23]]]][[1, 1]]]];
  coarseMinX = $coarseX[[localIdx]];
  coarseMinVal = coarseVals[[localIdx]];
  Print["Coarse minimum in [2,3]: x = ", N[coarseMinX, 12], ", f/N = ", N[coarseMinVal/$N, 12]];
  ,
  Print["No grid point in [2,3]!"];
  coarseMinX = 2.5714;
];

(* ---------------------------------------------------- *)
(* 5. Refine alpha in [2.5, 2.65]                        *)
(* ---------------------------------------------------- *)
(* Use paper's alpha as initial seed and bracket near it *)
valSeed = FourierSum[2.57144749848]/$N;
bracketLo = 2.55;
bracketHi = 2.59;
{refineTime, refineRes} = AbsoluteTiming @ FindMinimum[
  Total[Cos[x * ulamTerms]]/$N,
  {x, 2.57144749848, bracketLo, bracketHi},
  WorkingPrecision -> 30
];
alphaHatN = x /. refineRes[[2]];
depth = refineRes[[1]];
Print["Refined alphaHatN = ", N[alphaHatN, 16], " in ", refineTime, " s"];
Print["Depth f(alphaHatN)/N = ", N[depth, 12]];

McCranieLo = 2.57144749846;
McCranieHi = 2.57144749850;
inMcCranieInterval = (alphaHatN > McCranieLo && alphaHatN < McCranieHi);
Print["In McCranie interval? ", inMcCranieInterval];

(* ---------------------------------------------------- *)
(* 6. Exceptional set                                    *)
(* ---------------------------------------------------- *)
exceptionalSet = Select[ulamTerms, Cos[alphaHatN * #] >= 0 &];
Print["Exceptional set E = ", exceptionalSet];
Print["|E| = ", Length[exceptionalSet]];
knownExceptional = {2, 3, 47, 69};
exceptionalSetMatches = ContainsAll[exceptionalSet, knownExceptional];
Print["{2,3,47,69} subset of E? ", exceptionalSetMatches];

(* ---------------------------------------------------- *)
(* 7. Save results                                       *)
(* ---------------------------------------------------- *)
exp1Results = Association[
  "Nterms" -> $N,
  "maxTerm" -> maxTerm,
  "density" -> density,
  "alphaHatN" -> alphaHatN,
  "depth" -> depth,
  "inMcCranieInterval" -> inMcCranieInterval,
  "exceptionalSet" -> exceptionalSet,
  "exceptionalSetMatches" -> exceptionalSetMatches
];
Export["exp1_results.wxf", exp1Results];
Print["Saved exp1_results.wxf"];

Print["=== Experiment 1 complete ==="];

(* === Experiment 2: convergence and uncertainty of alpha_N === *)

SetDirectory[DirectoryName[$InputFileName]];

(* Load terms if not already present *)
If[! ValueQ[ulamTerms] || Length[ulamTerms] != 100000,
  ulamTerms = Import["ulam_terms.wxf"];
];
If[Length[ulamTerms] != 100000,
  Print["ERROR: expected 100000 terms in ulam_terms.wxf, got ", Length[ulamTerms]];
  Abort[]
];
$packedUlam = Developer`ToPackedArray[N[ulamTerms]];
$Nfull = Length[ulamTerms];

(* Fast machine-precision scalar sum *)
FourierSumMP[x_?NumericQ] := Total[Cos[x * $packedUlam]];

(* Chunked list evaluator (compiled, memory-safe) *)
cFourierSumList = Compile[{{xvals, _Real, 1}, {terms, _Real, 1}},
  Table[Total[Cos[x * terms]], {x, xvals}],
  CompilationTarget -> "C", RuntimeOptions -> "Speed"
];
FourierSumMPList[xs_List] := Module[
  {chunk = 500, n = Length[xs], res = {}},
  Do[
    res = Join[res, cFourierSumList[
      Developer`ToPackedArray[N[xs[[i ;; Min[i + chunk - 1, n]]]]],
      $packedUlam
    ]],
    {i, 1, n, chunk}
  ];
  res
];

(* ---------------------------------------------------- *)
(* 1. alphaConvergence for prefixes                     *)
(* ---------------------------------------------------- *)
prefixSizes = {1000, 3000, 10000, 30000, 100000};
alphaConvergence = Table[
  Module[
    {prefix, fs, nm = nk, t, res, alpha, depth},
    prefix = Take[ulamTerms, nk];
    fs[x_?NumericQ] := Total[Cos[x * prefix]]/nm;
    {t, res} = AbsoluteTiming @ TimeConstrained[
      FindMinimum[fs[x], {x, 2.5714476, 2.5, 2.65},
        WorkingPrecision -> 25, AccuracyGoal -> 20, PrecisionGoal -> 15],
      60, $Failed
    ];
    If[res === $Failed,
      {nk, $Failed, $Failed, t},
      alpha = x /. res[[2]];
      depth = res[[1]];
      {nk, N[alpha, 16], N[depth, 12], t}
    ]
  ],
  {nk, prefixSizes}
];

Print["alphaConvergence:"];
Print[TableForm[alphaConvergence, TableHeadings -> {None, {"N", "alphaHat", "depth", "time"}}]];

(* ---------------------------------------------------- *)
(* 2. Power-law drift                                   *)
(* ---------------------------------------------------- *)
mcLo = 2.57144749846;
mcHi = 2.57144749850;
mcMid = (mcLo + mcHi)/2;

validRows = alphaConvergence;
nkVals = #[[1]] & /@ validRows;
alphaVals = #[[2]] & /@ validRows;
depthVals = #[[3]] & /@ validRows;

drifts = Abs[alphaVals - mcMid];
logData = Transpose[{Log[N[1.0 / nkVals]], Log[N[drifts]]}];
lm = LinearModelFit[logData, {1, u}, u];
cLin = Exp[lm["BestFitParameters"][[1]]];
betaLin = lm["BestFitParameters"][[2]];

nlmObj = Quiet @ Check[
  NonlinearModelFit[
    Transpose[{N[nkVals, 25], N[alphaVals, 25]}],
    aInf + cc * nn^(-bb),
    {{aInf, mcMid}, {cc, cLin}, {bb, betaLin}},
    nn,
    WorkingPrecision -> 25
  ],
  $Failed
];

If[nlmObj =!= $Failed,
  nlmParams = nlmObj["BestFitParameters"];
  If[Head[nlmParams] === List && Head[nlmParams[[1]]] === Rule,
    {alphaInftyFree, cNlm, betaNlm} = {aInf, cc, bb} /. nlmParams,
    {alphaInftyFree, cNlm, betaNlm} = nlmParams
  ],
  {alphaInftyFree, cNlm, betaNlm} = {$Failed, $Failed, $Failed}
];

powerLawFit = Association[
  "C_linear" -> cLin,
  "beta_linear" -> betaLin,
  "alphaInfty_nonlinear" -> alphaInftyFree,
  "C_nonlinear" -> cNlm,
  "beta_nonlinear" -> betaNlm
];

Print["Linear fit: drift ~ ", N[cLin, 6], " * N^(-", N[betaLin, 6], ")"];
If[alphaInftyFree =!= $Failed,
  Print["Nonlinear fit: alphaInfty = ", N[alphaInftyFree, 12], ", C = ", N[cNlm, 6], ", beta = ", N[betaNlm, 6]],
  Print["Nonlinear fit failed."]
];

(* ---------------------------------------------------- *)
(* 3. Second derivative and half-width at N=100000      *)
(* ---------------------------------------------------- *)
alphaHat = alphaVals[[-1]];
depth100k = depthVals[[-1]];

hh = 1*^-8;
{v0, v1, vm1} = {FourierSumMP[alphaHat], FourierSumMP[alphaHat + hh], FourierSumMP[alphaHat - hh]};
fppOverN = (v1 - 2*v0 + vm1) / (hh^2 * $Nfull);
Print["f(alphaHat)=", v0];
Print["f(alphaHat+hh)=", v1];
Print["f(alphaHat-hh)=", vm1];
Print["f''(alphaHat)/N = ", N[fppOverN, 8]];

target = depth100k + 0.1;
bracketSize = 1*^-6;
rootR = FindRoot[
  FourierSumMP[x]/$Nfull - target,
  {x, alphaHat + bracketSize/2, alphaHat + bracketSize},
  WorkingPrecision -> 20, AccuracyGoal -> 12, PrecisionGoal -> 8
];
rootL = FindRoot[
  FourierSumMP[x]/$Nfull - target,
  {x, alphaHat - bracketSize, alphaHat - bracketSize/2},
  WorkingPrecision -> 20, AccuracyGoal -> 12, PrecisionGoal -> 8
];
wR = Abs[(x /. rootR) - alphaHat];
wL = Abs[(x /. rootL) - alphaHat];
halfWidth = Min[wR, wL];
Print["wR = ", N[wR, 8], "  wL = ", N[wL, 8], "  halfWidth = ", N[halfWidth, 8]];

(* ---------------------------------------------------- *)
(* 4. Baseline away from dip                            *)
(* ---------------------------------------------------- *)
baselineX = {0.5, 1.0, 1.5, 2.0, 3.0, 3.5};
baselineVals = Table[Abs[FourierSumMP[x]]/Sqrt[$Nfull], {x, baselineX}];
baselineStats = Association[
  "mean" -> Mean[baselineVals],
  "max" -> Max[baselineVals]
];
Print["Baseline |f|/Sqrt[N] at ", baselineX, " -> ", N[#, 4] & /@ baselineVals];
Print["Mean = ", N[baselineStats["mean"], 4], ", Max = ", N[baselineStats["max"], 4]];

(* ---------------------------------------------------- *)
(* 5. Harmonics                                         *)
(* ---------------------------------------------------- *)
paperHarmonics = {0.288, 0.253, -0.578, 0.580, -0.344, 0.057, 0.118}; (* ell=2..8 *)
harmonicData = Table[
  Module[{val = FourierSumMP[ell * alphaHat]/$Nfull},
    Print["ell = ", ell, ": f(ell alpha)/N = ", N[val, 8], " (paper c_ell = ", paperHarmonics[[ell - 1]], ")"];
    {ell, val}
  ],
  {ell, 2, 8}
];
harmonics = Association[
  "computed" -> harmonicData,
  "paper" -> paperHarmonics
];

(* ---------------------------------------------------- *)
(* 6. Plots                                             *)
(* ---------------------------------------------------- *)
Export["exp2_drift.png",
  ListLogLinearPlot[
    Transpose[{nkVals, alphaVals}],
    PlotRange -> All, AxesLabel -> {"N", "alphaHat(N)"},
    ImageSize -> 600, PlotMarkers -> Automatic
  ]
];

Export["exp2_dipzoom.png",
  Module[{dipGrid, dipVals},
    dipGrid = Subdivide[alphaHat - 0.01, alphaHat + 0.01, 1999];
    dipVals = FourierSumMPList[dipGrid] / $Nfull;
    ListLinePlot[
      Transpose[{dipGrid, dipVals}],
      PlotRange -> All, AxesLabel -> {"x", "f_N(x)/N"},
      ImageSize -> 600
    ]
  ]
];

(* ---------------------------------------------------- *)
(* 7. Save results                                      *)
(* ---------------------------------------------------- *)
exp2Results = Association[
  "alphaConvergence" -> alphaConvergence,
  "powerLawFit" -> powerLawFit,
  "secondDeriv" -> fppOverN,
  "halfWidth" -> halfWidth,
  "halfWidthDetails" -> Association["wR" -> wR, "wL" -> wL],
  "baselineStats" -> baselineStats,
  "harmonics" -> harmonicData
];
Export["exp2_results.wxf", exp2Results];
Print["Saved exp2_results.wxf"];
Print["=== Experiment 2 complete ==="];

(* === Experiment 3: controls — random sparse and Ulam(a,b) variants === *)
SetDirectory[DirectoryName[$InputFileName]];

ulamTerms = Import["ulam_terms.wxf"];
nUlam = 30000;
maxInt = Take[ulamTerms, nUlam][[-1]];
alphaUlam = 2.57144749848;
xGrid = Developer`ToPackedArray @ N @ Subdivide[0.5, N[Pi], 999];

(* --- Part A: random sparse controls --- *)
SeedRandom[20250625];
randomMinima = {};
randomAtAlpha = {};
For[i = 1, i <= 100, i++,
  r = Developer`ToPackedArray @ N @ Sort @ RandomSample[Range[maxInt], nUlam];
  vals = Total[Cos[Outer[Times, xGrid, r, 1]], {2}];
  AppendTo[randomMinima, Min[vals] / nUlam];
  AppendTo[randomAtAlpha, Total[Cos[alphaUlam * r]] / nUlam];
];

statsMin = Association[
  "mean" -> Mean[randomMinima],
  "std" -> StandardDeviation[randomMinima],
  "min" -> Min[randomMinima],
  "max" -> Max[randomMinima]];
statsAlpha = Association[
  "mean" -> Mean[randomAtAlpha],
  "std" -> StandardDeviation[randomAtAlpha],
  "min" -> Min[randomAtAlpha],
  "max" -> Max[randomAtAlpha]];

(* Ulam(1,2) N=30000 *)
ulam30 = Developer`ToPackedArray @ N @ Take[ulamTerms, nUlam];
ulam30Vals = Total[Cos[Outer[Times, xGrid, ulam30, 1]], {2}];
ulamMinGrid = Min[ulam30Vals] / nUlam;
ulamAtAlpha = Total[Cos[alphaUlam * ulam30]] / nUlam;

{refTime, refObj} = FindMinimum[
  Total[Cos[x * Take[ulamTerms, nUlam]]] / nUlam,
  {x, 2.57144749848, 2.55, 2.59},
  WorkingPrecision -> 30
];
alphaRef = x /. refObj;

zAlpha = (ulamAtAlpha - statsAlpha["mean"]) / statsAlpha["std"];
zMin = (ulamMinGrid - statsMin["mean"]) / statsMin["std"];
fracMin = N[Count[randomMinima, v_ /; v <= ulamMinGrid] / 100];
fracAlpha = N[Count[randomAtAlpha, v_ /; v <= ulamAtAlpha] / 100];

randomSummary = Association[
  "statsMin" -> statsMin,
  "statsAlpha" -> statsAlpha,
  "ulamMinGrid" -> ulamMinGrid,
  "ulamAtAlpha" -> ulamAtAlpha,
  "alphaRef" -> alphaRef,
  "depthRef" -> refObj[[1]],
  "zMin" -> zMin,
  "zAlpha" -> zAlpha,
  "fracMin" -> fracMin,
  "fracAlpha" -> fracAlpha
];

Export["exp3_random_results.wxf", randomSummary];

(* --- histogram --- *)
histPlot = Histogram[randomMinima, Automatic, "PDF",
  Epilog -> {Red, Thick, Line[{{ulamMinGrid, 0}, {ulamMinGrid, 50}}]},
  PlotLabel -> "Random minima (N=30000)", ImageSize -> 400];
Export["exp3_random_hist.png", histPlot];

(* --- Part B: Ulam(a,b) sequences --- *)
abGen = Compile[{{n, _Integer}, {mc, _Integer}, {a, _Integer}, {b, _Integer}},
  Module[{terms, count, last, next, cN, i, j},
    terms = Table[0, {n}]; count = Table[0, {mc}];
    terms[[1]] = a; terms[[2]] = b;
    If[a + b <= mc, count[[a + b]] = 1];
    last = b; cN = 2;
    While[cN < n,
      next = last + 1;
      While[next <= mc && count[[next]] != 1, next++];
      If[next > mc, Break[]];
      cN++; terms[[cN]] = next; last = next;
      For[i = 1, i < cN, i++,
        j = next + terms[[i]];
        If[j <= mc, count[[j]] = count[[j]] + 1]
      ];
    ];
    terms
  ], CompilationTarget -> "WVM", RuntimeOptions -> "Speed"];

abPairs = {{1, 3}, {1, 4}, {2, 3}, {2, 5}};
abTermsList = Table[abGen[30000, 10^7, pair[[1]], pair[[2]]], {pair, abPairs}];

piVal = N[Pi];
coarseX = Developer`ToPackedArray @ N @ Subdivide[0.05, piVal, 3999];
paperDict = <|{1, 3} -> 2.83349751, {1, 4} -> 0.506013502, {2, 3} -> 1.16501287|>;
partBres = {};
partBplots = {};

For[k = 1, k <= 4, k++,
  pair = abPairs[[k]];
  terms = abTermsList[[k]];
  len = Length[terms];
  packed = Developer`ToPackedArray @ N @ terms;
  vals = Total[Cos[Outer[Times, coarseX, packed, 1]], {2}];
  minIdx = First @ Ordering[vals, 1];
  cminX = coarseX[[minIdx]]; cminD = vals[[minIdx]] / len;
  {tG, rG} = FindMinimum[
    Total[Cos[x * terms]] / len,
    {x, cminX, Max[cminX - 0.05, 0.01], Min[cminX + 0.05, piVal]},
    WorkingPrecision -> 25];
  gA = x /. rG; gD = tG;
  pR = Missing["NA"];
  If[KeyExistsQ[paperDict, pair],
    pa = paperDict[pair];
    {tP, rP} = FindMinimum[
      Total[Cos[x * terms]] / len,
      {x, pa, Max[pa - 0.05, 0.01], Min[pa + 0.05, piVal]},
      WorkingPrecision -> 25];
    pR = {x /. rP, tP};
  ];
  AppendTo[partBres, <|
    "pair" -> pair,
    "N" -> len,
    "maxTerm" -> terms[[-1]],
    "coarseX" -> cminX,
    "coarseD" -> cminD,
    "globalA" -> gA,
    "globalD" -> gD,
    "paperA" -> If[KeyExistsQ[paperDict, pair], paperDict[pair], Missing[]],
    "paperR" -> pR,
    "coarseVals" -> vals
  |>];
  AppendTo[partBplots, ListLinePlot[Transpose[{coarseX, vals/len}], PlotRange -> All, PlotLabel -> pair]];
];

abGrid = GraphicsGrid[{
  {partBplots[[1]], partBplots[[2]]},
  {partBplots[[3]], partBplots[[4]]}
}, ImageSize -> 800];
Export["exp3_ab_scans.png", abGrid];

(* (2,5) structure check *)
lastDiffs = Union[Differences[abTermsList[[4]]], Method -> "Monitor"];
firstTerms25 = Take[abTermsList[[4]], 20];

(* Part C: Beatty *)
beatty = Floor[Range[30000] * GoldenRatio];
beattyPacked = Developer`ToPackedArray @ N @ beatty;
beattyVals = Total[Cos[Outer[Times, coarseX, beattyPacked, 1]], {2}];
beattyMinIdx = First @ Ordering[beattyVals, 1];
beattyMinX = coarseX[[beattyMinIdx]];
beattyMinD = beattyVals[[beattyMinIdx]] / 30000;
beattyMaxD = Max[Abs[beattyVals]] / 30000;

partCres = <|
  "beattyMinX" -> beattyMinX,
  "beattyMinD" -> beattyMinD,
  "beattyMaxD" -> beattyMaxD
|>;

(* Save aggregate results *)
exp3Results = Association[
  "random" -> randomSummary,
  "partB" -> partBres,
  "partC" -> partCres,
  "twoFiveDiffs" -> lastDiffs,
  "twoFivePrefix" -> firstTerms25
];
Export["exp3_results.wxf", exp3Results];

Print["=== Experiment 3 complete ==="];
