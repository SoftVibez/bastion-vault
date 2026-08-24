# Bastion Wallet

A minimal, immutable, single-owner USDT wallet, written from scratch, holding
a small amount of real money on a live chain — open sourced so anyone can try
to break it.

**If you find a way to withdraw funds as a non-owner, they're yours to keep.**
See [RULES.md](./RULES.md) for the exact terms, scope, and deadline.

| | |
|---|---|
| Network | Polygon (mainnet) |
| Token | USDT (PoS) — [`0xc2132D...B58e8F`](https://polygonscan.com/token/0xc2132D05D31c914a87C6611C10748AEb04B58e8F) |
| Contract | `Vault.sol` — address: `TBD, filled in at deployment` |
| Verified source | `TBD` (Polygonscan link, filled in at deployment) |
| Bounty | Entire vault balance (~$10 in USDT at launch) |
| Window | 7 days from deployment — see [RULES.md](./RULES.md) |
| Frontend | [`web/index.html`](./web/index.html) — connect-wallet dashboard, no backend |

## Why this exists

Most "unhackable wallet" claims are marketing. This is an attempt to be
honest about what that phrase can actually mean: not "provably invulnerable,"
but "small and simple enough that there's almost nowhere for a bug to hide."
The design bet is that **the safest wallet is the one that does the least.**

## What it is

`Vault` is about 60 lines of Solidity. It does exactly two things:

1. Accepts USDT from anyone (a plain ERC20 `transfer` to the contract's address).
2. Lets a single, immutable `owner` withdraw it (`withdraw` / `withdrawAll`).

That's the entire feature set. No upgradability, no proxy, no admin
functions, no support for any token other than the one fixed at deployment,
no external dependencies beyond OpenZeppelin's `SafeERC20` (for the token
transfer itself) and `forge-std` for testing.

```solidity
contract Vault {
    address public immutable owner;
    IERC20 public immutable token;

    function withdraw(uint256 amount) external onlyOwner { ... }
    function withdrawAll() external onlyOwner { ... }
    function balance() external view returns (uint256) { ... }
}
```

There is deliberately no `deposit()` function — ERC20 tokens can always be
sent to any address without that address's cooperation, so a special deposit
function would only add a second, redundant code path.

See [`src/Vault.sol`](./src/Vault.sol) for the full, commented source.

## Threat model / design decisions

| Decision | Reasoning |
|---|---|
| `owner` and `token` are `immutable`, set once in the constructor | No `transferOwnership` function exists at all, and the contract can never be pointed at a different token. Nothing to hijack. |
| No upgradability / no proxy | Upgradable contracts move the real attack surface to "who controls the upgrade," and proxy patterns carry their own bug class (storage collisions, uninitialized implementations). Skipped entirely. |
| `SafeERC20` instead of a raw `token.transfer()` call | Real mainnet USDT's `transfer` function famously does not return a `bool`, which breaks a naive ERC20 interface call outright. `SafeERC20` handles both compliant and non-compliant tokens correctly — an audited library is the right place to get this exactly right, not a hand-rolled check. Verified directly in `test_WithdrawWorksWithNonCompliantToken`. |
| Checks-effects-interactions ordering | The event is emitted before the token transfer, which is always the last operation in both `withdraw` and `withdrawAll`. |
| Custom errors instead of `require` strings | Cheaper, and equally clear for this size of contract. |
| No reentrancy guard | Only `owner` can call the withdrawal functions, and standard ERC20 `transfer` doesn't hand control back to the recipient mid-call the way a native ETH send to a contract can — there's no callback hook here to reenter through in the first place. |
| No support for any token other than the one fixed at deployment, no `delegatecall`, no arbitrary-call function | Every one of those is a documented source of real-world exploits. None of them are needed for "hold USDT, let the owner withdraw it," so none of them exist here. |

## What's explicitly *not* claimed

- This is not audited by a third party. It's a solo project reviewed with
  fuzzing, invariant testing, and static analysis — see below — not a
  substitute for a professional audit.
- $10 will not attract serious professional attention. Treat "nobody broke
  it" as "nobody tried hard," not as proof of anything. See
  [RULES.md](./RULES.md) for the honest framing.
- "Unhackable" isn't a real property software can have. The goal here is
  *small enough that a real read-through is feasible*, not invulnerability.
- The frontend in `web/` provides zero security of its own — it's a
  convenience UI. The contract's on-chain access control is the only thing
  that actually protects the funds; see the notice on the page itself.

## Verification

### Tests

```bash
forge test -vv
```

17 tests: unit tests for every function and revert path (including
construction, over-withdrawal, and ownership-immutability checks), fuzz
tests (10,000 runs each) confirming no non-owner address can ever withdraw
and no owner withdrawal can ever exceed the vault's balance, and dedicated
tests proving correct behavior against both a standard ERC20 token and one
that mimics real USDT's non-standard (no return value) `transfer` function.

### Invariants

```bash
forge test --match-contract VaultInvariantsTest -vv
```

A stateful fuzzer (256 runs × 100 calls each) drives the vault through random
sequences of deposits, owner withdrawals, and attacker withdrawal attempts,
and checks two invariants hold across all of them:

- `invariant_NoAttackerEverWithdraws` — no address other than `owner` ever
  extracts a unit of USDT, across thousands of randomized attempts.
- `invariant_BalanceNeverExceedsDeposits` — the vault can never pay out more
  than it ever received.

### Static analysis

```bash
python -m slither src/Vault.sol
```

Slither's only findings are informational pragma-version notices from
OpenZeppelin's own interface files (they deliberately use loose version
constraints for broad compatibility) — no access-control, reentrancy, or
arithmetic issues were flagged on the Vault itself.

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

forge script script/Deploy.s.sol:Deploy \
  --rpc-url $POLYGON_RPC_URL --broadcast --verify -vvvv
```

The deployer's address becomes the vault's immutable `owner`. Fund the
deployed address by sending USDT (PoS, on Polygon) to it directly — any
address can deposit. Once deployed, set `CONTRACT_ADDRESS` near the top of
[`web/index.html`](./web/index.html) to get the dashboard live.

## Rules of the challenge

See [RULES.md](./RULES.md) for exact scope, what counts as a win, what's out
of bounds, and what happens if the window closes with no winner.

## License

MIT — see [LICENSE](./LICENSE).
