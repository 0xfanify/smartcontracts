# Comandos para Verificar Contratos Individualmente

## Endereços dos Contratos Deployados
```
HYPETOKEN_ADDRESS=0x4EDeC9055a82B683a2a55ADdfD3270BE6283EbcA
MOCKAZURO_ADDRESS=0xfD9984f5c15941A772748Cf37E54807F40F0FecE
ORACLE_ADDRESS=0xC5721bAD2a6c561Ac98fa2A50225e039fa742f95
TEAMNFT_ADDRESS=0xbe1D98EC28500FA93fa159B0Ef6438A200764e3c
MOCKFANX_ADDRESS=0xFC1A98cD458b8792c24F66Ad6Af1d95cafd995Bc
FUNIFY_ADDRESS=0xEf0ed238a0081dfcA3f5976d564b32d832F1887B
SEASONFY_ADDRESS=0xD8FDdDb0dcdfECcA2E0d105EADD805dC749df306
```

## Comandos de Verificação

### 1. HypeToken (sem parâmetros)
```bash
forge verify-contract 0x4EDeC9055a82B683a2a55ADdfD3270BE6283EbcA src/tokens/HypeToken.sol:HypeToken \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6
```

### 2. MockAzuro (sem parâmetros)
```bash
forge verify-contract 0xfD9984f5c15941A772748Cf37E54807F40F0FecE src/mocks/MockAzuro.sol:MockAzuro \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6
```

### 3. Oracle (com parâmetro _mockAzuro)
```bash
forge verify-contract 0xC5721bAD2a6c561Ac98fa2A50225e039fa742f95 src/oracle/Oracle.sol:Oracle \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6 \
    --constructor-args $(cast abi-encode "constructor(address)" 0xfD9984f5c15941A772748Cf37E54807F40F0FecE)
```

### 4. TeamNFT (sem parâmetros)
```bash
forge verify-contract 0xbe1D98EC28500FA93fa159B0Ef6438A200764e3c src/tokens/TeamNFT.sol:TeamNFT \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6
```

### 5. MockFanX (sem parâmetros)
```bash
forge verify-contract 0xFC1A98cD458b8792c24F66Ad6Af1d95cafd995Bc src/mocks/MockFanX.sol:MockFanX \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6
```

### 6. Funify (com parâmetros _token e _oracle)
```bash
forge verify-contract 0xEf0ed238a0081dfcA3f5976d564b32d832F1887B src/fanify/Funify.sol:Funify \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6 \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0x4EDeC9055a82B683a2a55ADdfD3270BE6283EbcA 0xC5721bAD2a6c561Ac98fa2A50225e039fa742f95)
```

### 7. Seasonfy (com parâmetros _token, _oracle, _teamNFT, _mockFanX)
```bash
forge verify-contract 0xD8FDdDb0dcdfECcA2E0d105EADD805dC749df306 src/seasonfy/Seasonfy.sol:Seasonfy \
    --verifier-url 'https://api.routescan.io/v2/network/testnet/evm/88882/etherscan' \
    --etherscan-api-key "verifyContract" \
    --num-of-optimizations 200 \
    --compiler-version v0.8.20+commit.a1b79de6 \
    --constructor-args $(cast abi-encode "constructor(address,address,address,address)" 0x4EDeC9055a82B683a2a55ADdfD3270BE6283EbcA 0xC5721bAD2a6c561Ac98fa2A50225e039fa742f95 0xbe1D98EC28500FA93fa159B0Ef6438A200764e3c 0xFC1A98cD458b8792c24F66Ad6Af1d95cafd995Bc)
```

## Como Usar

### Verificar todos os contratos de uma vez:
```bash
./verify-contracts.sh
```

### Verificar um contrato específico:
Copie e cole o comando correspondente ao contrato que deseja verificar.

## Notas

- Todos os comandos usam a versão do compilador `v0.8.20+commit.a1b79de6`
- Otimizações configuradas para 200
- Verificador: Routescan para Chiliz testnet
- API Key: "verifyContract" 