# Rules of Engagement

**Status:** LIVE — real funds, real chain.
**Network:** Base (chain id 8453)
**Contract:** `Vault` — address published in [README.md](./README.md) once deployed.
**Prize:** the entire on-chain balance of the vault (~$10 in ETH at launch).
**Window:** 7 days from deployment — deadline published in [README.md](./README.md).

## You win if

You get any address that is **not** the vault's `owner` to successfully extract
ETH from the deployed `Vault` contract, using only the contract's public
interface, on-chain. That's it. If you can call `withdraw` or `withdrawAll`
(or find some other path funds can leave through) from an address that isn't
`owner` and it succeeds, the funds are yours to keep — screenshot/tx hash and
a short writeup, and I'll confirm publicly.

## In scope

- The `Vault` contract's logic: access control, arithmetic, reentrancy,
  anything reachable through its ABI or through constructing a malicious
  contract that interacts with it.
- Anything about the deployed bytecode vs. the published source that doesn't
  match (i.e. don't trust — verify).

## Out of scope (this isn't "hacking the wallet," it's hacking me)

- Social engineering, phishing, or otherwise trying to obtain the owner's
  private key directly from me.
- Attacking Base's sequencer, RPC providers, block explorers, or any
  infrastructure that isn't the `Vault` contract itself.
- Attacking this GitHub repo, my other accounts, or anything not the
  deployed contract.
- Denial of service (e.g. spamming RPC) rather than an actual fund
  extraction.

Findings outside scope are still welcome as responsible disclosure — just
don't expect them to pay out the prize.

## If nobody wins

If the 7-day window closes and the funds are still only withdrawable by the
owner, I match whatever the vault held at deployment, out of pocket,
separately from the contract.

## Why this is a meaningful test (and why it might not be)

Being honest about the limits of this exercise:

- A $10 bounty will not attract serious professional review. Treat any
  "nobody broke it" result as *"nobody bothered,"* not as an audit result.
- The contract is intentionally tiny (~50 lines) specifically so that a real
  read-through is feasible for anyone who wants to actually try, in an
  afternoon.
- This is not a substitute for a professional audit. Don't deploy a fork of
  this with real, non-toy amounts of money without one.
