# Oracles Integration

- [ ] Criar estrutura inicial do contrato `PriceOracle.sol` com suporte a `getLatestPrice()` usando interface da Pyth.
- [ ] Mapear os feeds de Fan Tokens e USD disponíveis na Pyth Network.
- [ ] Esboçar contrato `ScoreOracle.sol` com stub de função `getLatestScore(teamA, teamB)`.
- [ ] Documentar fontes de dados esportivos possíveis via Chainlink Functions.
- [ ] Criar estrutura base do contrato `HypeOracle.sol` com função `submitHypeScore(teamId, score)`.

---

# Stake CHZ e Fan Tokens

- [ ] Atualizar `CHZStake.sol` para garantir `approve()` no `unstake()` via `IERC20.transferFrom`.
- [ ] Criar `FanTokenStake.sol` com função `stake()` que:

  - [ ] Valida o stake.
  - [ ] Emite NFT de Time.
  - [ ] Cunha \$HYPE com bônus.

- [ ] Implementar `unstake()` que:

  - [ ] Requer que temporada tenha terminado.
  - [ ] Queima o NFT de Time (`TeamNFT.burn()`).
  - [ ] Retorna os Fan Tokens ao usuário.

- [ ] Escrever modifier `onlyWithValidNFT(teamId)` para uso no contrato de apostas.

---

# Claim Bug Fix

- [ ] Criar teste unitário para validar `claim()` com aposta válida e NFT correspondente.
- [ ] Garantir verificação se o jogo acabou e o usuário é vencedor antes do `claim()`.
- [ ] Proteger a função com `nonReentrant` e limitar repetições.
- [ ] Verificar consumo de gás com e sem NFTs no `claim()`.

---

# Backend (Oracles & Hype)

- [ ] Criar serviço `getLatestPrices()` usando Pyth e expor em `/api/prices`.
- [ ] Criar endpoint para submeter Hype Score via carteira assinando transação (`submitHypeScore(teamId, score)`).
- [ ] Implementar job de simulação de Chainlink Keeper para atualização de placar.
- [ ] Aplicar normalização de dados de redes sociais e armazenar Hype Score off-chain antes de enviar.

---

# Frontend

- [ ] Criar componente que exibe o NFT de Time com season e time atual.
- [ ] Adicionar botão de "Desfazer Stake" que queima o NFT e retorna Fan Token.
- [ ] Atualizar exibição de saldo de \$HYPE com tooltip explicando que ele é intransferível.
- [ ] Mostrar alerta amigável quando usuário tenta transferir NFT ou \$HYPE.

---

# Implantação

- [ ] Implementar script de deploy com parâmetros para `TeamNFT`, `HYPE`, `Stake`.
- [ ] Testar todo fluxo em testnet: stake → NFT → aposta → claim → unstake (NFT queimado).
- [ ] Verificar se NFT realmente é removido do `ownerOf` após `burn`.

---

# Team NFT (ERC-721 Não-Transferível)

- [x] Criar contrato `TeamNFT.sol` como ERC-721 com função `mintTo(address, teamId, seasonId)`.
- [x] Tornar o NFT **non-transferable** sobrescrevendo `transferFrom` e `approve` para revert.
- [x] Adicionar metadados `teamId` e `seasonId` no token URI.
- [x] Implementar função `burn(uint256 tokenId)` acessível apenas pelo contrato de stake.
- [x] Escrever teste unitário para garantir que `transfer` e `approve` revertam.

---

# Token \$HYPE (ERC-20 Não-Transferível)

- [x] Criar/atualizar o contrato \$HYPE para sobrescrever `transfer`, `transferFrom` e `approve`, revertendo toda tentativa de movimentação.
- [x] Validar que a cunhagem e queima estão atreladas apenas às funções de stake e unstake.
- [x] Escrever teste unitário para garantir a não-transferibilidade do \$HYPE.
