# Context — Sidon-set constructions for Ulam specificity control

## What a Sidon set is

A **Sidon set** (or **B₂ set**) is a set of integers in which every pairwise sum aᵢ + aⱼ (with i ≤ j) is distinct.  Equivalently, the equation aᵢ + aⱼ = aₖ + aₗ implies {i,j} = {k,l}.  Sidon sets are sparse (maximum size q in [1, q²]) and hand-engineered for sum-uniqueness — exactly the property the Ulam recursion enforces *stochastically*.

## Why this is the right adversarial control

The Ulam sequence is *not* a Sidon set (many pairs can share a sum; the Ulam rule only requires each integer to have *exactly one* representation).  But Sidon sets are the strongest "sparse, sum-structured" sequences available.  If even they fail to produce a deep Fourier dip, the Ulam phenomenon is genuinely tied to the Ulam construction, not to generic sparsity or sum-uniqueness.

## Constructions we will test

### 1. Bose construction (finite-field)

Let q be a prime power.  Represent elements of the finite field F_q as integers 0,…,q−1.  Define

    S_Bose(q) = { i·q + (i² mod q) : i = 0, 1, …, q−1 }

This set has size q, is contained in [0, q²), and is a classical Sidon set (Bose 1938).  We will map it to a strictly increasing sequence by sorting, then take the first N elements.  The density is ~1/q, i.e. ~1/√(max element), sparser than Ulam (~0.074).  To match Ulam density we can take a *scaled* prefix or a *thinned* variant.

### 2. Greedy Sidon set

Start with g₁ = 1.  For each n > 1, let gₙ be the smallest integer > gₙ₋₁ such that all pairwise sums among {g₁,…,gₙ} are distinct.  This is the Mian-Chowla-like greedy B₂ sequence (OEIS A005282).  Its growth is known to be roughly n², i.e. density ~0.5/√n.

### 3. Random-thinned control

Start with a random sparse sequence sampled without replacement from {1,…,M}.  Greedily remove elements whose sum collides with an existing sum.  The result is a randomized Sidon-ish set with tunable density.  This serves as a "structureless" sparse-sum-unique control.

## References (external, unverified)

- Bose, R. C. (1938). "On the construction of balanced incomplete block designs."  *Ann. Eugenics* 9, 353–399.
- Chowla, S. (1944). "Solution of a problem of Erdős."  *J. London Math. Soc.* 19, 204.
- OEIS A005282 (Mian-Chowla / greedy B₂ sequence).

## What we *do not* assume from these references

The constructions above are standard; we will not cite growth-rate asymptotics as results.  The only numbers that matter are the ones we compute in the kernel.
