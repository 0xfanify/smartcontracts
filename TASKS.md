# Oracle & Fanify & Seasonfy

- [ ] apenas admin pode criar um jogo
- [ ] o oracle deve buscar o preco no contrato `MockAzuro.sol` (o qual tem o mesmo é admin que o Oracle)
- [ ] quando criar o jogo ele passa a data do inicio do jogo
- [ ] os contratos de aposta devem consultar a data de inicio do jogo
- [ ] é possivel apostar apenas até o inicio do jogo
- [ ] quando o jogo inicia ele deve bloquear apostas
- [ ] 2h apos o jogo é liberado o premio


# Stake CHZ (Fanify)

- [ ] usuario faz stake de CHZ
- [ ] contrato busca o preço de CHZ/USD no oracle `getPrice("CHZ")`
- [ ] trava o CHZ
- [ ] emite $HYPE na proporção de 1000 HYPE pra 1 USD
- [ ] usuario pode apostar em qualquer time, a favor ou contra
- [ ] Usuário pode fazer unstake a qualquer momento

# Stake Fan Tokens (Seasonfy)

- [ ] usuario faz stake do Fantoken
- [ ] a lista de fantokens aceitos está o oraculo
- [ ] contrato busca o preço do  fantoken/USD no oracle `getPrice("CHZ")`
- [ ] transfere o Fantoken para o contrato chamado `MockFanX.sol` (o qual tem o mesmo admin que o Seasonfy)
- [ ] emite $HYPE na proporção de 1000 HYPE pra 1 USD
- [ ] emite um NFT do time para a carteira do usuario
- [ ] esse lock é até o fim da temporada
- [ ] o fim da temporada está no contrato
- [ ] o usuario só pode aposta a favor do time, e só nos jogo que o time dele está jogando (trava feita pelo NFT)
- [ ] o usuário pode apostar ou nao, mas nao pode apostar contra o time dele
- [ ] no fim da tempoda o Usuário pode fazer unstake a qualquer momento.

---

# Claim Bug Fix

- [x] Criar teste unitário para validar `claim()` com aposta válida e NFT correspondente.
- [x] Garantir verificação se o jogo acabou e o usuário é vencedor antes do `claim()`.
- [x] Proteger a função com `nonReentrant` e limitar repetições.
- [x] Verificar consumo de gás com e sem NFTs no `claim()`.

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
