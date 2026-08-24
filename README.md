# Bastion Wallet

A single, securely-generated wallet holding a small amount of real money on a
live chain — open sourced, with the address and frontend public, so anyone
can try to break it.

**If you get the funds out without my cooperation, they're yours to keep.**
See [RULES.md](./RULES.md) for the exact terms, scope, and deadline.

| | |
|---|---|
| Network | Polygon (mainnet) |
| Token | USDT (PoS) — [`0xc2132D...B58e8F`](https://polygonscan.com/token/0xc2132D05D31c914a87C6611C10748AEb04B58e8F) |
| Wallet address | [`0x5c737c3b0ea2399b4BA434e6e5e689521bEB9405`](https://polygonscan.com/address/0x5c737c3b0ea2399b4BA434e6e5e689521bEB9405) |
| Live dashboard | **[softvibez.github.io/bastion-vault](https://softvibez.github.io/bastion-vault/)** |
| Bounty | Entire wallet balance (~$10 in USDT) |
| Window | 7 days from funding — see [RULES.md](./RULES.md) |

## What this is

Exactly what it sounds like: one private key, one address, no smart contract,
no backend. The `docs/index.html` page (source of truth in [`web/index.html`](./web/index.html))
is a static dashboard — balance, receive address, connect-and-send — that
reads directly from the Polygon chain and asks a connected wallet (e.g.
MetaMask) to sign anything it needs signed. The page itself holds no keys and
enforces nothing; it's a convenience window onto public chain data.

## Why a plain wallet, not a smart contract

This project started as a from-scratch smart-contract vault (see
[Earlier design](#earlier-design-not-currently-live) below) on the theory
that a tiny, heavily-tested contract with an immutable owner check would be
about as hard to break as a solo project reasonably gets. That's still true
— but deploying a contract turned out to need a separate native gas token on
whatever chain it lived on, and getting even a small amount of that gas
token proved to be a real, multi-day logistical obstacle unrelated to
security. A plain wallet needs no deployment at all: funding it *is* the
entire setup.

Worth being honest about the tradeoff this makes: a smart contract's
`onlyOwner` check and a plain wallet's key custody are actually protecting
against the same underlying thing — whoever holds the signing key. The
contract's real extra value would only show up against a *logic bug* letting
someone bypass that check without the key; since we'd already kept that
contract deliberately minimal and tested it hard, that risk was already
small. Dropping it removes an already-small risk at zero real cost, given
both designs share an identical key-custody dependency for the same single
owner. See [`RULES.md`](./RULES.md) for what "hacking" this actually means
under this design.

## Threat model

| What's true | Why it matters |
|---|---|
| The private key is a properly-generated random 256-bit number (`cast wallet new`, standard secp256k1) | Guessing or brute-forcing it is not "hard" — it's computationally infeasible with any realistic amount of compute. This is the same math securing all of Bitcoin and Ethereum. |
| The key has never been imported into any service that stores it remotely | No custodial exchange, no cloud wallet, no third party holds a copy. |
| The frontend never touches the private key | It only ever requests signatures through a connected wallet extension (e.g. MetaMask); the raw key never enters the page's JavaScript context. |
| No admin backdoor, no recovery mechanism, no second key | There's genuinely nothing else to target — key custody is the entire security model, by design, not by omission. |

## What's explicitly *not* claimed

- This is not a professional security audit of anything — it's one person's
  key-handling practices, held to public scrutiny.
- $10 will not attract serious researcher attention. "Nobody broke it" means
  "nobody tried hard," not "this is provably secure."
- "Unhackable" isn't a real property anything can have. The honest claim is
  narrower: the only real attack surface here is key exposure, and real
  effort has gone into making sure that hasn't happened (see
  [RULES.md](./RULES.md) for exactly what's in/out of scope).

## Building / viewing locally

The frontend is a single static file, no build step:

```bash
git clone https://github.com/SoftVibez/bastion-vault
cd bastion-vault
# open web/index.html directly, or serve it with any static file server
```

## Earlier design (not currently live)

Before settling on the plain-wallet approach above, this project built a
from-scratch Solidity smart-contract wallet — immutable single owner, no
upgradability, no admin backdoor, covered by 17 tests including 10,000-run
fuzz tests and a stateful invariant suite. It was never deployed and holds
no funds. The code is kept in the repo as a documented alternative, not as
part of the live challenge:

- [`src/Vault.sol`](./src/Vault.sol) — the contract
- [`test/`](./test/) — unit, fuzz, and invariant tests (`forge test -vv`)
- [`script/Deploy.s.sol`](./script/Deploy.s.sol) — deploy script, unused

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation)
to build/test: `forge install && forge build && forge test -vv`.

## Rules of the challenge

See [RULES.md](./RULES.md) for exact scope, what counts as a win, what's out
of bounds, and what happens if the window closes with no winner.

## License

MIT — see [LICENSE](./LICENSE).
