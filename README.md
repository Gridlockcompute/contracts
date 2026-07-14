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
| `GridStaking` | GRID ERC20 staking pool — approve + `deposit(uint256)` (`EVM_GRID_STAKING`) |
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

## Phased deploy (mainnet)

Robinhood Chain mainnet is chain `4663`. Set `ROBINHOOD_RPC` and fund the deployer wallet with ETH for gas.

| Phase | Script | Deploys |
|-------|--------|---------|
| 4a | `script/Deploy.s.sol` | `GridlockRegistry`, `Attestation` |
| 4b | `script/DeployPhase4b.s.sol` | `FeeCollector`, `JobRouter` (needs `EVM_WORKER_REGISTRY`) |
| 5 | `script/DeployPhase5.s.sol` | `GridStaking` (needs `EVM_GRID_TOKEN`) |
| 6 | `script/DeployPhase6.s.sol` | `GridlockGovernance` (needs `EVM_FEE_COLLECTOR`, optional `GOVERNANCE_TIMELOCK_SEC`) |
| Handoff | `script/DeployFeeCollectorHandoff.s.sol` | New `FeeCollector` with governance as `authority` |

Example — Phase 5 (GridStaking):

```bash
export ROBINHOOD_RPC=https://rpc.mainnet.chain.robinhood.com
export EVM_GRID_TOKEN=0x62537c09a874cfe886e052d5afcd28356a98e549
export PRIVATE_KEY=0x...

forge script script/DeployPhase5.s.sol \
  --rpc-url $ROBINHOOD_RPC \
  --private-key $PRIVATE_KEY \
  --broadcast
```

Verify on [Blockscout](https://robinhoodchain.blockscout.com):

```bash
forge verify-contract <GRID_STAKING_ADDRESS> \
  src/GridStaking.sol:GridStaking \
  --chain-id 4663 \
  --rpc-url $ROBINHOOD_RPC \
  --verifier blockscout \
  --verifier-url https://robinhoodchain.blockscout.com/api/ \
  --etherscan-api-key unused \
  --constructor-args $(cast abi-encode "constructor(address)" $EVM_GRID_TOKEN) \
  --watch
```

Broadcast artifacts land in `broadcast/<Script>/4663/` (gitignored).

## Mainnet contract addresses (chain 4663)

| Contract | Address | Status |
|----------|---------|--------|
| GRID token | [`0x62537c09a874cfe886e052d5afcd28356a98e549`](https://robinhoodchain.blockscout.com/address/0x62537c09a874cfe886e052d5afcd28356a98e549) | Live |
| GridlockRegistry | [`0xC3F9E16d21F88DC5a7d89317EEC0e1c62206E1Cb`](https://robinhoodchain.blockscout.com/address/0xC3F9E16d21F88DC5a7d89317EEC0e1c62206E1Cb) | Live |
| Attestation | [`0xD82dC78E2B2B079820E54513bEf4F6649c15b2dA`](https://robinhoodchain.blockscout.com/address/0xD82dC78E2B2B079820E54513bEf4F6649c15b2dA) | Live |
| JobRouter | [`0xfEEa8b7b2B90CE699238c23a03f0607972150446`](https://robinhoodchain.blockscout.com/address/0xfEEa8b7b2B90CE699238c23a03f0607972150446) | Live |
| FeeCollector | [`0x2604413db30ef67f28dc50e88daBfC89d6F1f4e0`](https://robinhoodchain.blockscout.com/address/0x2604413db30ef67f28dc50e88daBfC89d6F1f4e0) | Live (governance handoff) |
| GridStaking | [`0x32C074317C86318f5a41137E64AEf611324CA9A9`](https://robinhoodchain.blockscout.com/address/0x32C074317C86318f5a41137E64AEf611324CA9A9) | Live (verified) |
| GridlockGovernance | [`0x124cA42770B8DDcD8e6a9D2EF5201c0b0165eE4E`](https://robinhoodchain.blockscout.com/address/0x124cA42770B8DDcD8e6a9D2EF5201c0b0165eE4E) | Live |

## Router integration

After deploy, set addresses on the [router](https://github.com/Gridlockcompute/router):

```env
EVM_GRID_TOKEN=0x62537c09a874cfe886e052d5afcd28356a98e549
EVM_WORKER_REGISTRY=0xC3F9E16d21F88DC5a7d89317EEC0e1c62206E1Cb
EVM_JOB_ROUTER=0xfEEa8b7b2B90CE699238c23a03f0607972150446
EVM_FEE_COLLECTOR=0x2604413db30ef67f28dc50e88daBfC89d6F1f4e0
EVM_ATTESTATION=0xD82dC78E2B2B079820E54513bEf4F6649c15b2dA
EVM_GRID_STAKING=0x32C074317C86318f5a41137E64AEf611324CA9A9
EVM_GOVERNANCE=0x124cA42770B8DDcD8e6a9D2EF5201c0b0165eE4E

# Enable gradually after validation
GRID_STAKING_ONCHAIN_ENABLED=true
EVM_SETTLEMENT_ENABLED=false
WORKER_REGISTRY_ONCHAIN_ENABLED=false
JOB_ROUTER_ONCHAIN_ENABLED=false
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
