# contracts

Solidity programs for [Gridlock](https://grid-lock.tech) on [Robinhood Chain](https://chain.robinhood.com) (EVM). Optional on-chain hooks for worker registry, job anchoring, fee distribution, staking, and timelocked governance.

**Production router:** [https://api.grid-lock.tech](https://api.grid-lock.tech)

## Contracts

| Contract | Role |
|----------|------|
| `GridlockRegistry` | Worker registration + oracle attestation updates (`EVM_WORKER_REGISTRY`) |
| `Attestation` | TEE / confidential-capability attestations |
| `JobRouter` | Oracle-anchored job submit / complete / cancel (`EVM_JOB_ROUTER`) |
| `FeeCollector` | Native ETH fee routing — 60% stakers / 20% workers / 10% burn / 10% treasury (`EVM_FEE_COLLECTOR`) |
| `GridStaking` | Native ETH staking pool (`EVM_GRID_STAKING`) |
| `GridlockGovernance` | Timelocked `FeeCollector` pool updates + `distributeFees` (`EVM_GOVERNANCE`) |

> **Naming:** the on-chain type is `GridlockRegistry`. The router env var is `EVM_WORKER_REGISTRY` (historical alias).

## Build

```bash
# From monorepo root (gridlock/)
pnpm contracts:build
pnpm sync:evm-abis   # copies ABIs → packages/evm/src/abis/
```

Or inside this directory:

```bash
forge build
```

## Phased deploy (testnet or mainnet)

Set `ROBINHOOD_RPC` and fund the deployer wallet. Use Robinhood testnet (`46630`) for dry runs; mainnet is chain `4663`.

| Phase | Script | Deploys |
|-------|--------|---------|
| 4a | `script/Deploy.s.sol` | `GridlockRegistry`, `Attestation` |
| 4b | `script/DeployPhase4b.s.sol` | `FeeCollector`, `JobRouter` (needs `EVM_WORKER_REGISTRY`) |
| 5 | `script/DeployPhase5.s.sol` | `GridStaking` |
| 6 | `script/DeployPhase6.s.sol` | `GridlockGovernance` (needs `EVM_FEE_COLLECTOR`, optional `GOVERNANCE_TIMELOCK_SEC`) |
| Handoff | `script/DeployFeeCollectorHandoff.s.sol` | New `FeeCollector` with governance as `authority` |

Example (testnet):

```bash
export ROBINHOOD_RPC=https://rpc.testnet.chain.robinhood.com
export PRIVATE_KEY=0x...

forge script script/Deploy.s.sol --rpc-url $ROBINHOOD_RPC --broadcast

export EVM_WORKER_REGISTRY=0x...   # from Deploy.s.sol output
forge script script/DeployPhase4b.s.sol --rpc-url $ROBINHOOD_RPC --broadcast

forge script script/DeployPhase5.s.sol --rpc-url $ROBINHOOD_RPC --broadcast

export EVM_FEE_COLLECTOR=0x...     # from Phase 4b
export GOVERNANCE_TIMELOCK_SEC=86400
forge script script/DeployPhase6.s.sol --rpc-url $ROBINHOOD_RPC --broadcast

export EVM_GOVERNANCE=0x...
export EVM_GRID_STAKING=0x...
forge script script/DeployFeeCollectorHandoff.s.sol --rpc-url $ROBINHOOD_RPC --broadcast
```

Broadcast artifacts land in `broadcast/<Script>/<chainId>/`.

### Robinhood testnet (46630) — latest recorded deploys

| Contract | Address |
|----------|---------|
| GridlockRegistry | `0xbe5d140dfbe9b9efe91789a96c7769c52154ed84` |
| Attestation | `0x00bceb696b6b8852e75a08789e4534fbddb5e46c` |
| JobRouter | `0xc7c17d2780fb1d4632ca694fbeda54774f7a0225` |
| FeeCollector (phase 4b) | `0x283828409b2a1892f359a9257e437c04c629f4d8` |
| GridStaking | `0x9f4f924ed087e2acd68999899086d05bbe64f2b5` |
| GridlockGovernance | `0x1710a4e88118ef37dbc9426d208bdd05d6a80bd5` |
| FeeCollector (handoff) | `0x202194f58c89d44a8dae17031dbb0b75551c9571` |

Use the **handoff** `FeeCollector` as the canonical address once governance is live.

**Mainnet (4663):** not deployed yet — no `broadcast/*/4663/` artifacts.

## Router integration

After deploy, set addresses on the [router](https://github.com/Gridlockcompute/router):

```env
EVM_WORKER_REGISTRY=0x...
EVM_JOB_ROUTER=0x...
EVM_FEE_COLLECTOR=0x...
EVM_ATTESTATION=0x...
EVM_GRID_STAKING=0x...
EVM_GOVERNANCE=0x...

# Enable gradually after validation
EVM_SETTLEMENT_ENABLED=false
WORKER_REGISTRY_ONCHAIN_ENABLED=false
JOB_ROUTER_ONCHAIN_ENABLED=false
GRID_STAKING_ONCHAIN_ENABLED=false
EVM_ATTESTATION_ENABLED=false
CHAIN_INDEXER_ENABLED=false
```

ABIs consumed by `@gridlock/evm` (`packages/evm`) — sync with `pnpm sync:evm-abis` after every contract change.

## Tests

```bash
forge test
```

## Related repos

| Repo | Role |
|------|------|
| [router](https://github.com/Gridlockcompute/router) | API + optional on-chain hooks |
| [frontend](https://github.com/Gridlockcompute/frontend) | Dashboard, staking UI |
| [native-worker](https://github.com/Gridlockcompute/native-worker) | Headless worker CLI |
| [worker-desktop](https://github.com/Gridlockcompute/worker-desktop) | Desktop worker app |
