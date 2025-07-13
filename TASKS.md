# Oracles Integration

* [ ] Criar estrutura inicial do contrato `PriceOracle.sol` com suporte a `getLatestPrice()` usando interface da Pyth.
* [ ] Mapear os feeds de Fan Tokens e USD disponíveis na Pyth Network.
* [ ] Esboçar contrato `ScoreOracle.sol` com stub de função `getLatestScore(teamA, teamB)`.
* [ ] Documentar possíveis fontes de dados para placares em Chainlink (Keepers, Functions).
* [ ] Criar estrutura base do contrato `HypeOracle.sol` com função `submitHypeScore(teamId, score)`.

---

# Team NFT (ERC-721)

* [ ] Criar contrato básico ERC-721 usando OpenZeppelin para `TeamNFT.sol`.
* [ ] Adicionar suporte a metadados `teamId` e `seasonId` no NFT.
* [ ] Implementar função `mintTo(address, teamId, seasonId)` no contrato `TeamNFT`.
* [ ] Escrever teste unitário simples para verificação de `balanceOf()` e `tokenURI()`.

---

# Token $HYPE

* [ ] Auditar função de `mint` e `burn` no contrato atual do $HYPE.
* [ ] Implementar função `mintWithOraclePrice(address user, uint256 chzAmount)` no contrato.
* [ ] Escrever teste unitário para validar mint baseado em preços da Pyth Network.

---

# Stake CHZ e Fan Tokens

* [ ] Atualizar contrato `CHZStake.sol` para verificar `approve()` corretamente no `unstake()`.
* [ ] Criar função `stakeFanToken()` que emite NFT após stake bem-sucedido.
* [ ] Esboçar lógica para restringir apostas com base na posse de NFT (`onlyWithTeamNFT()` modifier).
* [ ] Adicionar testes básicos de fluxo: `stake → mint NFT → try bet`.

---

# Claim Bug Fix

* [ ] Criar teste unitário para validar `claim()` com aposta vencedora.
* [ ] Escrever verificação explícita de elegibilidade no `claim()` (ex: partida finalizada).
* [ ] Adicionar `nonReentrant` na função `claim()` para prevenir ataques.
* [ ] Medir consumo de gás da função `claim()` com Hardhat.

---

# Backend (Oracles & Hype)

* [ ] Criar função `fetchFanTokenPrices()` no backend usando endpoint da Pyth.
* [ ] Escrever serviço `submitHypeToChain()` para enviar score ao contrato via carteira.
* [ ] Criar cron job `checkMatchResults()` simulando Chainlink Keepers.
* [ ] Testar endpoint de consulta ao Hype Score com cache e normalização aplicada.

---

# Frontend

* [ ] Adicionar componente de visualização do NFT de time na UI do usuário.
* [ ] Criar botão de "Apostar com NFT" que verifica o saldo de `TeamNFT`.
* [ ] Implementar exibição do preço do Fan Token via chamada ao contrato `PriceOracle`.
* [ ] Adicionar tela de feedback para `claim()` com status e mensagens de erro.

---

# Testes & Auditoria

* [ ] Escrever 1 teste unitário por contrato novo: `PriceOracle`, `ScoreOracle`, `HypeOracle`, `TeamNFT`.
* [ ] Rodar testes de integração locais entre stake, NFT e aposta.
* [ ] Escrever checklist pré-auditoria com funções críticas por contrato.
* [ ] Criar relatório de cobertura de testes com Hardhat ou Foundry.

---

# Implantação

* [ ] Escrever script de deploy para `TeamNFT.sol` na testnet.
* [ ] Rodar deploy e salvar endereços em `.env` do backend e frontend.
* [ ] Testar stake e emissão de NFT na testnet simulando interação real.
* [ ] Validar integração frontend ↔ contratos na testnet com usuário teste.

