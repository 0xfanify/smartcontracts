#!/bin/bash

# Script para verificar todos os contratos deployados
# Carrega os endereços do arquivo deployedContracts.txt

echo "🔍 Iniciando verificação de todos os contratos..."
echo "================================================"

# Carregar endereços do arquivo
source deployedContracts.txt

# Verificar HypeToken (sem parâmetros)
echo ""
echo "📦 [1/7] Verificando HypeToken..."
forge verify-contract $HYPETOKEN_ADDRESS src/tokens/HypeToken.sol:HypeToken \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6

# Verificar MockAzuro (sem parâmetros)
echo ""
echo "📦 [2/7] Verificando MockAzuro..."
forge verify-contract $MOCKAZURO_ADDRESS src/mocks/MockAzuro.sol:MockAzuro \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6

# Verificar Oracle (com parâmetro _mockAzuro)
echo ""
echo "📦 [3/7] Verificando Oracle..."
forge verify-contract $ORACLE_ADDRESS src/oracle/Oracle.sol:Oracle \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6 \
    --constructor-args $(cast abi-encode "constructor(address)" $MOCKAZURO_ADDRESS)

# Verificar TeamNFT (sem parâmetros)
echo ""
echo "📦 [4/7] Verificando TeamNFT..."
forge verify-contract $TEAMNFT_ADDRESS src/tokens/TeamNFT.sol:TeamNFT \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6

# Verificar MockFanX (sem parâmetros)
echo ""
echo "📦 [5/7] Verificando MockFanX..."
forge verify-contract $MOCKFANX_ADDRESS src/mocks/MockFanX.sol:MockFanX \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6

# Verificar Funify (com parâmetros _token e _oracle)
echo ""
echo "📦 [6/7] Verificando Funify..."
forge verify-contract $FUNIFY_ADDRESS src/fanify/Funify.sol:Funify \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6 \
    --constructor-args $(cast abi-encode "constructor(address,address)" $HYPETOKEN_ADDRESS $ORACLE_ADDRESS)

# Verificar Seasonfy (com parâmetros _token, _oracle, _teamNFT, _mockFanX)
echo ""
echo "📦 [7/7] Verificando Seasonfy..."
forge verify-contract $SEASONFY_ADDRESS src/seasonfy/Seasonfy.sol:Seasonfy \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6 \
    --constructor-args $(cast abi-encode "constructor(address,address,address,address)" $HYPETOKEN_ADDRESS $ORACLE_ADDRESS $TEAMNFT_ADDRESS $MOCKFANX_ADDRESS)

echo ""
echo "🎉 Verificação de todos os contratos finalizada!"
echo "================================================"
echo "📋 Endereços dos contratos verificados:"
echo "HypeToken: $HYPETOKEN_ADDRESS"
echo "MockAzuro: $MOCKAZURO_ADDRESS"
echo "Oracle: $ORACLE_ADDRESS"
echo "TeamNFT: $TEAMNFT_ADDRESS"
echo "MockFanX: $MOCKFANX_ADDRESS"
echo "Funify: $FUNIFY_ADDRESS"
echo "Seasonfy: $SEASONFY_ADDRESS" 