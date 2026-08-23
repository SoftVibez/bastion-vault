# Bastion Vault

A minimal, immutable, single-owner ETH vault, written from scratch, holding a
small amount of real money on a live chain — open sourced so anyone can try
to break it.

**If you find a way to withdraw funds as a non-owner, they're yours to keep.**
See [RULES.md](./RULES.md) for the exact terms, scope, and deadline.

| | |
|---|---|
| Network | Base (mainnet) |
| Contract | `Vault.sol` — address: `TBD, filled in at deployment` |
| Verified source | `TBD` (Basescan link, filled in at deployment) |
| Bounty | Entire vault balance (~$10 in ETH at launch) |
| Window | 7 days from deployment — see [RULES.md](./RULES.md) |

## Why this exists

Most "unhackable wallet" claims are marketing. This is an attempt to be
honest about what that phrase can actually mean: not "provably invulnerable,"
but "small and simple enough that there's almost nowhere for a bug to hide."
The design bet is that **the safest wallet is the one that does the least.**

## What it is

`Vault` is ~50 lines of Solidity. It does exactly two things:

1. Accepts ETH from anyone (`receive()`).
2. Lets a single, immutable `owner` withdraw it (`withdraw` / `withdrawAll`).

That's the entire feature set. No upgradability, no proxy, no admin
functions, no token support, no external dependencies beyond `forge-std` for
testing (not used in the deployed contract itself).

```solidity
contract Vault {
    address public immutable owner;

    receive() external payable { ... }          // anyone can deposit
    function withdraw(uint256 amount) external onlyOwner { ... }
    function withdrawAll() external onlyOwner { ... }
    function balance() external view returns (uint256) { ... }
}
```

See [`src/Vault.sol`](./src/Vault.sol) for the full, commented source.

## Threat model / design decisions

| Decision | Reasoning |
|---|---|
| `owner` is `immutable`, set once in the constructor | No `transferOwnership` function exists at all — there is nothing to hijack. Ownership itself is not an attack surface. |
| No upgradability / no proxy | Upgradable contracts move the real attack surface to "who controls the upgrade," and proxy patterns carry their own bug class (storage collisions, uninitialized implementations). Skipped entirely. |
| No external calls except the final ETH transfer | Fewer external calls means fewer places for reentrancy or malicious callback behavior to matter. |
| Checks-effects-interactions ordering | State (the event log) is written before the ETH transfer, which is always the last operation in both `withdraw` and `withdrawAll`. |
| Custom errors instead of `require` strings | Cheaper, and equally clear for this size of contract. |
| No reentrancy guard | Only `owner` can call the withdrawal functions. A non-owner can't reenter because they can never pass `onlyOwner` in the first place. The only entity that could "attack via reentrancy" is the owner attacking themselves, which isn't a meaningful threat. This is verified explicitly in `test_ReentrancyDuringWithdrawCannotDrainExtra`. |
| No token support, no `delegatecall`, no arbitrary-call function | Every one of those is a documented source of real-world exploits. None of them are needed for "hold ETH, let the owner withdraw it," so none of them exist here. |

## What's explicitly *not* claimed

- This is not audited by a third party. It's a solo project reviewed with
  fuzzing, invariant testing, and static analysis — see below — not a
  substitute for a professional audit.
- $10 will not attract serious professional attention. Treat "nobody broke
  it" as "nobody tried hard," not as proof of anything. See
  [RULES.md](./RULES.md) for the honest framing.
- "Unhackable" isn't a real property software can have. The goal here is
  *small enough that a real read-through is feasible*, not invulnerability.

## Verification

### Tests

```bash
forge test -vv
```

16 tests: unit tests for every function and revert path, fuzz tests (10,000
runs each) confirming no non-owner address can ever withdraw and no owner
withdrawal can ever exceed the vault's balance, and a reentrancy test using a
malicious owner contract.

### Invariants

```bash
forge test --match-contract VaultInvariantsTest -vv
```

A stateful fuzzer (256 runs × 100 calls each) drives the vault through random
sequences of deposits, owner withdrawals, and attacker withdrawal attempts,
and checks two invariants hold across all of them:

- `invariant_NoAttackerEverWithdraws` — no address other than `owner` ever
  extracts a wei, across thousands of randomized attempts.
- `invariant_BalanceNeverExceedsDeposits` — the vault can never pay out more
  than it ever received.

### Static analysis

```bash
python -m slither src/Vault.sol
```

Slither's only finding is informational: the use of a low-level `.call` to
send ETH. That's the deliberate, recommended pattern here (avoiding the fixed
2300-gas stipend that `.transfer`/`.send` impose, which itself has caused
real incidents) — no access-control, reentrancy, or arithmetic issues were
flagged.

## Building / running locally

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

```bash
git clone <this repo>
cd bastion-vault
forge install
forge build
forge test -vv
```

## Deploying your own instance

```bash
cp .env.example .env
# fill in .env with a FRESH burner key — never reuse a wallet you use elsewhere

# dry run on testnet first
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify -vvvv

# then mainnet, once you've tried to break it yourself on testnet
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $BASE_RPC_URL --broadcast --verify -vvvv
```

The deployer's address becomes the vault's immutable `owner`. Fund the
deployed address by sending ETH to it directly — any address can deposit.

## Rules of the challenge

See [RULES.md](./RULES.md) for exact scope, what counts as a win, what's out
of bounds, and what happens if the window closes with no winner.

## License

MIT — see [LICENSE](./LICENSE).
