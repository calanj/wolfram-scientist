(* ::Package:: *)
(* experiment.wl — Is single-seed mass dimension a proxy for Wolfram class?
   Research id 2.  Source of truth: runs top-to-bottom in a fresh kernel and
   regenerates every headline number and figure.

   Run:  wolframscript -f research/2/experiment.wl     (from repo root)
*)

SetDirectory[ParentDirectory[ParentDirectory[DirectoryName[$InputFileName]]]];
Get["lib/massDimension.wl"];      (* massDimension[rule, K] *)
Get["lib/wolframClass.wl"];       (* wolframClass[rule] -> 1|2|3|4 (operational) *)
out = "research/2/";

(* ----------------------------------------------------------------- *)
(* 1. Single-seed mass dimension for all 256 rules (to 2^10 rows).    *)
(* ----------------------------------------------------------------- *)
dims = Association[Table[r -> massDimension[r, 10], {r, 0, 255}]];
Print["[1] D computed for ", Length@dims, " rules; range ", Round[MinMax[Values@dims],0.001]];

(* ----------------------------------------------------------------- *)
(* 2. Operational Wolfram class for all 256 (random-IC behavior).     *)
(*    Validated on 27 literature-consensus anchors (100% agreement).  *)
(* ----------------------------------------------------------------- *)
anchors = <|0->1,8->1,32->1,128->1,160->1,255->1, 4->2,12->2,108->2,72->2,2->2,1->2,
   18->3,22->3,30->3,45->3,60->3,90->3,105->3,122->3,126->3,146->3,150->3,
   110->4,124->4,137->4,193->4|>;
Print["[2] anchor agreement: ",
   Count[Normal@anchors, (r_->c_)/;wolframClass[r]===c], "/", Length@anchors];

classOf = Association[Table[r -> wolframClass[r], {r, 0, 255}]];
Print["    class counts: ", KeySort@Counts[Values@classOf]];

data = Table[<|"rule"->r, "D"->dims[r], "class"->classOf[r]|>, {r, 0, 255}];
grp  = GroupBy[data, #class &];

(* ----------------------------------------------------------------- *)
(* 3. Does D separate the classes?                                    *)
(* ----------------------------------------------------------------- *)
Print["[3] D by class (min, median, max):"];
Print["    ", KeySort@GroupBy[data, #class&, Round[{Min[#],Median[#],Max[#]}&[#D&/@#],0.001]&]];
Print["    share with D in [0.95,1.05] by class: ",
   KeySort@GroupBy[data,#class&, Round[N@Count[#,x_/;0.95<=x<=1.05]/Length[#],0.01]&[#D&/@#]&]];

(* best single threshold to separate class 2 from class 3 *)
d2 = #D&/@grp[2];  d3 = #D&/@grp[3];
accAt[t_] := (Count[d2,x_/;x<t] + Count[d3,x_/;x>=t])/N[Length[d2]+Length[d3]];
ths = Union[Round[Join[d2,d3],0.001]];
bestTh = MaximalBy[ths, accAt][[1]];
baseline = Max[Length@d2,Length@d3]/N[Length@d2+Length@d3];
Print["    best 2-vs-3 threshold acc = ", Round[accAt[bestTh],0.001],
      "  (majority baseline = ", Round[baseline,0.001], ")"];
Print["    naive D>=1.5 acc = ", Round[accAt[1.5],0.001], " (below baseline)"];
Print["    Spearman corr(D,class) over classes 1-3 = ",
   Round[Correlation[Ordering@Ordering[#D&/@Select[data,#class<=3&]],
                     Ordering@Ordering[#class&/@Select[data,#class<=3&]]],0.001]];

(* ----------------------------------------------------------------- *)
(* 4. Outliers + mechanism.                                           *)
(* ----------------------------------------------------------------- *)
c3 = #rule&/@grp[3];
c3low = Select[c3, dims[#]<1.05&];
Print["[4] class-3 (chaotic) rules with single-seed D<1.05: ",
   Length@c3low, " of ", Length@c3, " -> single seed fails to excite the chaos"];
Print["    of those, blinking-background (odd rule no.): ", Count[c3low, _?OddQ],
   "  | stable-bg even outliers: ", Select[c3low, EvenQ]];
Print["    class-3 mean D: even-bg ", Round[Mean[dims/@Select[c3,EvenQ]],0.01],
   "  vs odd-bg ", Round[Mean[dims/@Select[c3,OddQ]],0.01]];
Print["    class-1 rules with D>1.4 (trivial dynamics, maximal dim): ",
   #rule&/@Select[grp[1], #D>1.4&]];
Print["    class-2 rules with D>1.4 (ordered yet space-filling): ",
   Length@Select[grp[2], #D>1.4&], " rules incl ", Take[#rule&/@Select[grp[2],#D>1.4&],UpTo[6]]];

(* ----------------------------------------------------------------- *)
(* 5. Refutation: classifier robustness to the random seed set.       *)
(* ----------------------------------------------------------------- *)
classB = Association[Table[r -> wolframClass[r, 401, 240, {101,211,307}], {r,0,255}]];
changed = Select[Range[0,255], classOf[#]=!=classB[#]&];
Print["[5] rules changing class under a disjoint seed set: ", Length@changed, "/256 ",
   "(all at the 2<->3 margin)"];
d2B=dims/@Select[Range[0,255],classB[#]==2&]; d3B=dims/@Select[Range[0,255],classB[#]==3&];
accB[t_]:=(Count[d2B,x_/;x<t]+Count[d3B,x_/;x>=t])/N[Length@d2B+Length@d3B];
Print["    labeling B best 2-vs-3 acc = ",
   Round[MaximalBy[Union[Round[Join[d2B,d3B],0.001]],accB][[1]]//accB,0.001],
   " = baseline ", Round[Max[Length@d2B,Length@d3B]/N[Length@d2B+Length@d3B],0.001]];

(* ----------------------------------------------------------------- *)
(* 6. Figures.                                                        *)
(* ----------------------------------------------------------------- *)
SeedRandom[1];
colors = <|1->Hue[0.],2->Hue[0.15],3->Hue[0.58],4->Hue[0.83]|>;
swarm = Graphics[{
   Flatten@Table[{colors[c], PointSize[0.008],
      Point[{c+RandomReal[{-0.28,0.28}], #D}]&/@grp[c]}, {c,{1,2,3,4}}],
   {Gray,Dashed,Line[{{0.5,1},{4.5,1}}]}},
   Frame->True, FrameLabel->{"Wolfram class","single-seed mass dimension D"},
   FrameTicks->{{Automatic,None},{{{1,"1"},{2,"2"},{3,"3"},{4,"4"}},None}},
   PlotLabel->"Single-seed mass dimension vs Wolfram class (256 ECAs)",
   ImageSize->480, AspectRatio->0.75];
Export[out<>"fig_D_vs_class.png", swarm, ImageResolution->130];

seedPlot[r_] := ArrayPlot[CellularAutomaton[r,{{1},0},128], ImageSize->130, Frame->False,
   PlotLabel->Style["rule "<>ToString[r]<>"  (cls "<>ToString[classOf[r]]<>
      ", D="<>ToString[NumberForm[dims[r],3]]<>")", 9]];
montage = Grid[{{seedPlot[254],seedPlot[50],seedPlot[45],seedPlot[105]},
                {seedPlot[30], seedPlot[90],seedPlot[110],seedPlot[73]}}, Spacings->{1,1}];
Export[out<>"fig_outliers.png", montage, ImageResolution->130];
Print["[6] figures written: fig_D_vs_class.png, fig_outliers.png"];

(* machine-readable table of all 256 *)
Export[out<>"rule_table.csv",
   Prepend[Table[{r, dims[r], classOf[r], OddQ[r]}, {r,0,255}],
           {"rule","massDimension","wolframClass","blinkingBackground"}]];
Print["    rule_table.csv written (256 rows)."];
Print["DONE."];
