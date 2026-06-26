(* ============================================================
   ulam.wl
   Counter-based (Gibbs-style) sieve for Ulam-type sequences.

   ulamSequence[n]       -> first n terms of A002858 (a_1=1, a_2=2)
   ulamSequence[{a,b}, n] -> first n terms of the Ulam-type (a,b) rule

   Rule: a_1 = a, a_2 = b; each next term is the smallest integer > previous
   that is expressible as a sum of two DISTINCT earlier terms in EXACTLY ONE
   way.

   Algorithm: maintain a representation-count vector
     count[k] = #{(i,j) : i < j, a_i + a_j = k}
   and pick the smallest k > a_last with count[k] == 1. Each new term
   triggers an O(currentN) update of count. Total cost is roughly linear in
   the largest term reached.

   Usage:

     << "lib/ulam.wl"
     ulamSequence[20]
     (* {1, 2, 3, 4, 6, 8, 11, 13, 16, 18, 26, 28, 36, 38, 47, 48, 53, 57, 62, 69} *)

     terms = ulamSequence[100000];
     Length[terms]                   (* 100000 *)
     Last[terms]                     (* 1351223 *)

     terms = ulamSequence[{1, 3}, 10000];
     Take[terms, 10]                 (* {1, 3, 4, 5, 6, 8, 10, 12, 17, 21} *)

   Origin: research/ulam-hidden-periodicity (2026-06-25).
   ============================================================ *)

ulamSequenceCompiled = Compile[{{a, _Integer}, {b, _Integer},
   {nTerms, _Integer}, {maxCount, _Integer}},
  Module[
    {terms, count, last, next, currentN, i, j},
    terms = Table[0, {nTerms}];
    count = Table[0, {maxCount}];
    terms[[1]] = a;
    terms[[2]] = b;
    If[a + b <= maxCount, count[[a + b]] = 1];
    last = b;
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

(* Density of A002858 is ≈ 0.0740. For erratic (a,b) the density varies but
   the sieve self-corrects: if maxCount was too small the compiled core
   returns a trailing zero and we retry with a bigger buffer. *)
ulamSequence[{a_Integer, b_Integer}, nTerms_Integer] := Module[
  {maxCount, terms, headroom},
  headroom = 200000;
  maxCount = Ceiling[nTerms / 0.05] + headroom;
  terms = ulamSequenceCompiled[a, b, nTerms, maxCount];
  While[terms[[-1]] == 0,
    maxCount = 2 * maxCount;
    terms = ulamSequenceCompiled[a, b, nTerms, maxCount];
    If[maxCount > 5 * 10^9,
      Message[ulamSequence::overflow, {a, b}, nTerms];
      Return[$Failed]
    ];
  ];
  terms
];

ulamSequence[nTerms_Integer] := ulamSequence[{1, 2}, nTerms];

ulamSequence::overflow = "Could not fit `1` Ulam-type sequence of length `2` \
within maxCount budget; sieve aborted.";
