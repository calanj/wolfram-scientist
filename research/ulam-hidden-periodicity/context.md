# Context — Ulam hidden periodicity

## Sources

- **Steinerberger 2015** — *A Hidden Signal in the Ulam Sequence*,
  arXiv:1507.00267 (v6, 6 Jul 2016). Source PDF was fetched and read.
- **OEIS A002858** — Ulam numbers (the sequence itself).

## Steinerberger 2015 — what the paper actually claims (external; unverified
until our kernel reproduces it)

- Ulam sequence: a_1=1, a_2=2, a_n = smallest integer > a_{n-1} representable
  as a sum of two *distinct* earlier elements in *exactly one* way.
  First terms: 1, 2, 3, 4, 6, 8, 11, 13, 16, 18, 26, 28, 36, 38, 47, …
- The Fourier sum f_N(x) = Σ_{n≤N} cos(x · a_n) is typically of order √N for
  x away from 0, BUT exhibits a sharp negative dip f_N(α) ≈ -0.8·N at a
  specific
  > **α ≈ 2.5714474995…**
- For N = 10^7, the empirical statement is:
  > cos(α · a_n) < 0 for all a_n except a_n ∈ {2, 3, 47, 69}.
- McCranie (2.4·10^9 elements, cited in the paper) reports the bounds
  > 2.57144749846 < α < 2.57144749850.
- No closed form for α is known. The author writes "we expect this property
  to be exceedingly rare" among naturally-arising sequences.
- Other Ulam-type (a,b) starts (with "erratic" consecutive differences)
  reportedly have their own α:
  - (a,b)=(1,3) → α ≈ 2.83349751… (at N = 2.5·10^6)
  - (a,b)=(1,4) → α ≈ 0.506013502… (at N = 3.9·10^6)
  - (a,b)=(2,3) → α ≈ 1.16501287… (at N = 5.7·10^6)
- For "non-erratic" starts (eventually periodic differences, e.g. (2,5),
  (4,n) with n ≡ 1 mod 4), peaks at 2π/k from mod-k structure are *not* the
  same phenomenon.
- Empirical density of A002858 is ≈ 0.0739 (citing the Strottman / McCranie
  data set).

## What we use this for

- The headline target α and the exceptional set {2, 3, 47, 69} are concrete
  numerical predictions; we will compute them in-kernel and compare.
- The "other (a,b)" α's give a built-in specificity check: if they too
  reproduce in our shorter runs, the phenomenon is robust within the Ulam
  family; if not, that informs how much N we need.
- The paper's caveat about peaks at 2π/k from arithmetic structure means a
  flat random-sparse control is the right artifact check, NOT a periodic
  Ulam-type.

## Caveats

- All numbers above are **external** and treated as unverified targets until
  reproduced in the kernel.
- Our compute budget (N ≤ 10^5) is well below the paper's N = 10^7, so:
  - The signal magnitude min_x f_N(x)/N may not yet be near -0.8; the paper's
    own Fig. 1/2 at N=50,100 show only a hint of the dip.
  - We will be unable to verify the full exceptional set at 10^7; we can only
    check whether our smaller exceptional set is a subset of {2, 3, 47, 69}
    and whether anything else slips through at our N.
