#!/usr/bin/env bash
# verify.sh — Reproducible verification for Mist Multisig Wallet (4088b optimized)
# Compiles wallet/wallet.sol from dapp-bin commit 69cb5e8c8207 and diffs against on-chain bytecode.
# Usage: ./verify.sh
# Dependencies: node (for solc-js), curl, python3

set -e

ETHERSCAN_API="https://api.etherscan.io/api"
CONTRACT="0x1fad12be55386d48388367513f1f04cbef77949c"
COMPILER_VERSION="v0.3.0+commit.11d67369"
SOLJSON_URL="https://github.com/ethereum/solc-bin/raw/gh-pages/bin/soljson-${COMPILER_VERSION}.js"
SOLJSON_FILE="/tmp/soljson-${COMPILER_VERSION}.js"

echo "=== Mist Multisig Wallet (4088b) Bytecode Verification ==="
echo ""

# Step 1: Download compiler
if [ ! -f "$SOLJSON_FILE" ]; then
  echo "[1/4] Downloading soljson ${COMPILER_VERSION}..."
  curl -sL "$SOLJSON_URL" -o "$SOLJSON_FILE"
else
  echo "[1/4] Using cached soljson ${COMPILER_VERSION}"
fi

# Step 2: Compile Wallet.sol with optimizer ON, 200 runs
echo "[2/4] Compiling Wallet.sol (optimizer ON, 200 runs)..."
COMPILE_RESULT=$(node -e "
  const solc = require('$SOLJSON_FILE');
  const fs = require('fs');
  const src = fs.readFileSync('$(dirname \$0)/Wallet.sol', 'utf8');
  const input = JSON.stringify({
    language: 'Solidity',
    sources: { 'Wallet.sol': { content: src } },
    settings: {
      optimizer: { enabled: true, runs: 200 },
      outputSelection: { '*': { '*': ['evm.deployedBytecode.object'] } }
    }
  });
  // Use legacy compile if JSON interface not available
  let output;
  if (solc.compileStandardWrapper) {
    output = JSON.parse(solc.compileStandardWrapper(input));
  } else if (solc.compile && typeof solc.compile === 'function') {
    // Older API: compile(source, optimize)
    const legacy = solc.compile(src, 1);
    output = legacy;
    const contracts = Object.keys(legacy.contracts || {});
    // Find the main wallet contract (last in inheritance chain)
    const walletKey = contracts.find(k => k.includes('Wallet') && !k.includes('multi'));
    if (walletKey) {
      process.stdout.write(legacy.contracts[walletKey].runtimeBytecode || '');
    }
    process.exit(0);
  }
  // Extract wallet contract (the outermost inheriting contract)
  const contracts = output.contracts['Wallet.sol'];
  const name = Object.keys(contracts).find(n => n === 'Wallet' || n === 'wallet');
  const bytecode = contracts[name].evm.deployedBytecode.object;
  process.stdout.write(bytecode);
" 2>/dev/null)

if [ -z "$COMPILE_RESULT" ]; then
  echo "ERROR: Compilation failed or produced empty bytecode"
  exit 1
fi

echo "$COMPILE_RESULT" > /tmp/compiled-4088.hex
COMPILED_SIZE=$(( ${#COMPILE_RESULT} / 2 ))
echo "  Compiled runtime size: ${COMPILED_SIZE} bytes"

# Step 3: Fetch on-chain bytecode
echo "[3/4] Fetching on-chain runtime bytecode..."
ONCHAIN=$(curl -s "${ETHERSCAN_API}?module=proxy&action=eth_getCode&address=${CONTRACT}&tag=latest" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][2:])" 2>/dev/null)

if [ -z "$ONCHAIN" ]; then
  echo "ERROR: Could not fetch on-chain bytecode (no Etherscan API key provided)"
  echo "  Set ETHERSCAN_API_KEY env var or pass key to the URL"
  echo ""
  echo "  Manual check: https://etherscan.io/address/${CONTRACT}#code"
  exit 1
fi

echo "$ONCHAIN" > /tmp/onchain-4088.hex
ONCHAIN_SIZE=$(( ${#ONCHAIN} / 2 ))
echo "  On-chain runtime size: ${ONCHAIN_SIZE} bytes"

# Step 4: Diff
echo "[4/4] Comparing bytecode..."
if [ "$COMPILE_RESULT" = "$ONCHAIN" ]; then
  echo ""
  echo "✅ EXACT MATCH — compiled output matches on-chain bytecode byte-for-byte"
  echo "   Contract: ${CONTRACT}"
  echo "   Compiler: ${COMPILER_VERSION}, optimizer ON"
  echo "   Size: ${COMPILED_SIZE} bytes"
else
  echo ""
  echo "❌ MISMATCH"
  diff <(echo "$COMPILE_RESULT" | fold -w2) <(echo "$ONCHAIN" | fold -w2) | head -20
  exit 1
fi
