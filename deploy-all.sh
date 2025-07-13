#!/bin/bash

# Script master para deploy de todos os contratos usando forge create
# Executa os deploys em sequência e captura os endereços automaticamente

RPC_URL="https://x-api-key:t-6859e688783f495f8d570bd6-06901fcc8dfb494aada1194a@chiliz-testnet.gateway.tatum.io/"

echo "🚀 Iniciando deploy completo dos contratos..."
echo "================================================"

# Função para extrair endereço do output do forge create
extract_address() {
    local output="$1"
    echo "$output" | grep -o "Deployed to: 0x[a-fA-F0-9]\{40\}" | cut -d' ' -f3
}

# 1. Deploy HypeToken
echo ""
echo "📦 [1/7] Deployando HypeToken..."
HYPETOKEN_OUTPUT=$(forge create src/tokens/HypeToken.sol:HypeToken \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --verifier blockscout \
    --verifier-url https://scan.chiliz.com/api/)

HYPETOKEN_ADDRESS=$(extract_address "$HYPETOKEN_OUTPUT")
echo "✅ HypeToken deployado em: $HYPETOKEN_ADDRESS"

# 2. Deploy MockAzuro
echo ""
echo "📦 [2/7] Deployando MockAzuro..."
MOCKAZURO_OUTPUT=$(forge create src/mocks/MockAzuro.sol:MockAzuro \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --verifier blockscout \
    --verifier-url https://scan.chiliz.com/api/)

MOCKAZURO_ADDRESS=$(extract_address "$MOCKAZURO_OUTPUT")
echo "✅ MockAzuro deployado em: $MOCKAZURO_ADDRESS"

# 3. Deploy Oracle
echo ""
echo "📦 [3/7] Deployando Oracle..."
ORACLE_OUTPUT=$(forge create src/oracle/Oracle.sol:Oracle \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --verifier blockscout \
    --verifier-url https://scan.chiliz.com/api/ \
    --constructor-args "$MOCKAZURO_ADDRESS")

ORACLE_ADDRESS=$(extract_address "$ORACLE_OUTPUT")
echo "✅ Oracle deployado em: $ORACLE_ADDRESS"

# 4. Deploy TeamNFT
echo ""
echo "📦 [4/7] Deployando TeamNFT..."
TEAMNFT_OUTPUT=$(forge create src/tokens/TeamNFT.sol:TeamNFT \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --verifier blockscout \
    --verifier-url https://scan.chiliz.com/api/)

TEAMNFT_ADDRESS=$(extract_address "$TEAMNFT_OUTPUT")
echo "✅ TeamNFT deployado em: $TEAMNFT_ADDRESS"

# 5. Deploy MockFanX
echo ""
echo "📦 [5/7] Deployando MockFanX..."
MOCKFANX_OUTPUT=$(forge create src/mocks/MockFanX.sol:MockFanX \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --verifier blockscout \
    --verifier-url https://scan.chiliz.com/api/)

MOCKFANX_ADDRESS=$(extract_address "$MOCKFANX_OUTPUT")
echo "✅ MockFanX deployado em: $MOCKFANX_ADDRESS"

# 6. Deploy Funify
echo ""
echo "📦 [6/7] Deployando Funify..."
FUNIFY_OUTPUT=$(forge create src/fanify/Funify.sol:Funify \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --verifier blockscout \
    --verifier-url https://scan.chiliz.com/api/ \
    --constructor-args "$HYPETOKEN_ADDRESS" "$ORACLE_ADDRESS")

FUNIFY_ADDRESS=$(extract_address "$FUNIFY_OUTPUT")
echo "✅ Funify deployado em: $FUNIFY_ADDRESS"

# 7. Deploy Seasonfy
echo ""
echo "📦 [7/7] Deployando Seasonfy..."
SEASONFY_OUTPUT=$(forge create src/seasonfy/Seasonfy.sol:Seasonfy \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --verifier blockscout \
    --verifier-url https://scan.chiliz.com/api/ \
    --constructor-args "$HYPETOKEN_ADDRESS" "$ORACLE_ADDRESS" "$TEAMNFT_ADDRESS" "$MOCKFANX_ADDRESS")

SEASONFY_ADDRESS=$(extract_address "$SEASONFY_OUTPUT")
echo "✅ Seasonfy deployado em: $SEASONFY_ADDRESS"

# Configurar dependências entre contratos
echo ""
echo "🔧 Configurando dependências entre contratos..."

# Set Fanify contract in HypeToken
echo "📝 Configurando HypeToken.setFanifyContract..."
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --sig "setFanifyContract(address)" \
    -- "$FUNIFY_ADDRESS" > /dev/null 2>&1

# Set Seasonfy contract in HypeToken
echo "📝 Configurando HypeToken.setSeasonfyContract..."
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --sig "setSeasonfyContract(address)" \
    -- "$SEASONFY_ADDRESS" > /dev/null 2>&1

# Set stake contract in TeamNFT
echo "📝 Configurando TeamNFT.setStakeContract..."
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url "$RPC_URL" \
    --account spicy \
    --broadcast \
    --gas-price 6000000000000 \
    --priority-gas-price 2000000000000 \
    --sig "setStakeContract(address)" \
    -- "$SEASONFY_ADDRESS" > /dev/null 2>&1

echo ""
echo "🎉 Deploy completo finalizado!"
echo "================================================"
echo "📋 Endereços dos contratos:"
echo "HypeToken: $HYPETOKEN_ADDRESS"
echo "MockAzuro: $MOCKAZURO_ADDRESS"
echo "Oracle: $ORACLE_ADDRESS"
echo "TeamNFT: $TEAMNFT_ADDRESS"
echo "MockFanX: $MOCKFANX_ADDRESS"
echo "Funify: $FUNIFY_ADDRESS"
echo "Seasonfy: $SEASONFY_ADDRESS"
echo ""
echo "💾 Salvando endereços em deployedContracts.txt..."
echo "HYPETOKEN_ADDRESS=$HYPETOKEN_ADDRESS" > deployedContracts.txt
echo "MOCKAZURO_ADDRESS=$MOCKAZURO_ADDRESS" >> deployedContracts.txt
echo "ORACLE_ADDRESS=$ORACLE_ADDRESS" >> deployedContracts.txt
echo "TEAMNFT_ADDRESS=$TEAMNFT_ADDRESS" >> deployedContracts.txt
echo "MOCKFANX_ADDRESS=$MOCKFANX_ADDRESS" >> deployedContracts.txt
echo "FUNIFY_ADDRESS=$FUNIFY_ADDRESS" >> deployedContracts.txt
echo "SEASONFY_ADDRESS=$SEASONFY_ADDRESS" >> deployedContracts.txt
echo "✅ Endereços salvos!" 