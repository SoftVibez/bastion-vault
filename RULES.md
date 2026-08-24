# Rules of Engagement

**Status:** LIVE — real funds, real chain.
**Network:** Polygon (chain id 137)
**Token:** USDT (PoS) — [`0xc2132D...B58e8F`](https://polygonscan.com/token/0xc2132D05D31c914a87C6611C10748AEb04B58e8F)
**Wallet address:** [`0x5c737c3b0ea2399b4BA434e6e5e689521bEB9405`](https://polygonscan.com/address/0x5c737c3b0ea2399b4BA434e6e5e689521bEB9405)
**Prize:** the entire USDT balance held by that address (~$10 at launch).
**Window:** 7 days from funding — deadline published in [README.md](./README.md).

## What this actually is

This is a **plain wallet** — one private key, one address. There is no smart
contract governing it, no deployed code, no `onlyOwner` check to find a bug
in. The entire feature set is a public/private keypair on a standard EVM
chain. See [README.md](./README.md) for why that's the honest design here.

## You win if

You get the private key controlling `0x5c737c3b0ea2399b4BA434e6e5e689521bEB9405`
— by any means that counts as actually *breaking* something, not by asking me
for it. In practice, since there's no contract logic to exploit, this means
one thing: successfully compromising the key itself (through a genuine
technical flaw, not social engineering — see below). If you move funds out of
this address without my cooperation, they're yours to keep — screenshot/tx
hash and a short writeup, and I'll confirm publicly.

## In scope

- Any technical flaw in how this specific key was generated, stored, or
  handled that a third party could independently exploit (e.g. if the
  generation process itself were flawed — it wasn't, but that's the category
  of thing that would count).
- Anything about the published frontend (`docs/index.html` /
  [the live site](https://softvibez.github.io/bastion-vault/)) that leaks
  key material or tricks a legitimate signer into an unintended transaction
  (e.g. a bug that misrepresents a transaction's destination or amount).

## Out of scope (this isn't "hacking the wallet," it's hacking me)

- Social engineering, phishing, or otherwise trying to obtain the private
  key directly from me through persuasion rather than a technical exploit.
- Attacking Polygon's validators, RPC providers, block explorers, Bitnob,
  Vercel/GitHub Pages, or any infrastructure that isn't this specific key or
  the frontend code itself.
- Exploiting a bug in the USDT token contract itself — that's Tether's
  attack surface, not this project's.
- Attacking this GitHub repo's hosting, my other accounts, or anything not
  directly this wallet.
- Denial of service rather than an actual fund extraction.

Findings outside scope are still welcome as responsible disclosure — just
don't expect them to pay out the prize.

## If nobody wins

If the 7-day window closes and the funds are still only movable by me, I
match whatever the wallet held at the start of the window, out of pocket.

## Why this is a meaningful test (and why it might not be)

Being honest about the limits of this exercise:

- A $10 bounty will not attract serious professional review. Treat any
  "nobody broke it" result as *"nobody bothered,"* not as an audit result.
- Because this is a plain keypair rather than a smart contract, the
  interesting "find a logic bug" angle mostly doesn't apply — brute-forcing
  or guessing a properly generated private key is not computationally
  feasible with any amount of realistic effort. The only genuinely open
  question is key handling, which is why the frontend's own code is
  explicitly in scope.
- This is not a substitute for professional security practice. Don't treat
  "I wasn't hacked" as validation of anything beyond this specific setup.

## Earlier design (not currently live)

This repo also contains a from-scratch Solidity smart-contract wallet
(`src/Vault.sol`, tests, deploy script) built and fuzz-tested earlier in this
project's history, before switching to the current plain-wallet design for
practical funding reasons. It was never deployed and holds no funds — it's
kept in the repo as a documented alternative approach, not as part of the
live challenge. See the note in [README.md](./README.md).
