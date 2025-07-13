#!/bin/bash

# Script master para deploy de todos os contratos usando forge create
# Executa os deploys em sequência e captura os endereços automaticamente

RPC_URL="https://x-api-key:t-6859e688783f495f8d570bd6-06901fcc8dfb494aada1194a@chiliz-testnet.gateway.tatum.io/"

echo "🚀 Iniciando deploy completo dos contratos..."
echo "================================================"

forge script script/Deploy.s.sol:DeployScript \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --sender $(cast wallet address --account spicy) \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000
