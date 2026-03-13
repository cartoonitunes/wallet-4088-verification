# Mist Multisig Wallet (4088b, optimized) — Bytecode Verification

Byte-for-byte bytecode verification for the **optimized Mist Multisig Wallet** deployed on Ethereum mainnet in May 2016. This is a template contract shared by **16 wallets holding ~526 ETH combined**.

## Contract Details

| Field | Value |
|---|---|
| Representative address | [`0x1fad12be55386d48388367513f1f04cbef77949c`](https://ethereumhistory.com/contract/0x1fad12be55386d48388367513f1f04cbef77949c) |
| Deployment tx | [`0x3441038cc325594a9ff12e1f4fc31f6bff0b6b461821fb8ee58e40875562ce5c`](https://etherscan.io/tx/0x3441038cc325594a9ff12e1f4fc31f6bff0b6b461821fb8ee58e40875562ce5c) |
| Block | 1,528,964 |
| Deployment date | May 16, 2016, 17:14:40 UTC |
| Deployer | `0x711a8720b458700cc3512e9950c18d745b41dac9` |
| Runtime bytecode size | 4,088 bytes |
| Contracts sharing bytecode | 16 |
| Total ETH held (all 16) | ~526 ETH |

## Source

- **Repository**: [`ethereum/dapp-bin`](https://github.com/ethereum/dapp-bin)
- **File**: `wallet/wallet.sol`
- **Commit**: [`69cb5e8c8207`](https://github.com/ethereum/dapp-bin/tree/69cb5e8c8207) (Dec 14, 2015 — "Rename 'from'")
- **Author**: Gav Wood (`g@ethdev.com`)

## Compiler

| Field | Value |
|---|---|
| Version | `solc v0.3.0+commit.11d67369` |
| Optimizer | ON |
| Optimizer runs | 200 |
| Language | Solidity |

## Key Insight: Optimizer Shrinks 6546b → 4088b

This contract uses the **same source code** as the unoptimized Mist wallet template (6,546 bytes). Enabling the Solidity optimizer reduces the runtime bytecode from 6,546 bytes to 4,088 bytes — a 37.6% reduction. Both templates were in common use during the Homestead era (March–September 2016).

The unoptimized variant (6,546b) is documented at [`cartoonitunes/wallet-6546-verification`](https://github.com/cartoonitunes/wallet-6546-verification) (if published).

## Verification

See [`verify.sh`](./verify.sh) for a reproducible verification script. It:

1. Downloads `soljson-v0.3.0+commit.11d67369.js` from the official Solidity release
2. Compiles `Wallet.sol` with optimizer enabled (200 runs)
3. Fetches the on-chain runtime bytecode via Etherscan
4. Diffs compiled output vs on-chain — should be identical

## Part of Ethereum History

This proof is part of the [Awesome Ethereum Proofs](https://github.com/cartoonitunes/awesome-ethereum-proofs) collection and documented at [Ethereum History](https://ethereumhistory.com/contract/0x1fad12be55386d48388367513f1f04cbef77949c).
