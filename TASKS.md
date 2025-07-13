Implemente essa consulta da seguinte forma:

1. user faz stake
2. contrato busca o preço do CHZ ou FAN token no oracle
3. oracle busca o preço em Dolar no MockAzuro
@/src 
[ ] Contrato busca o preço de ETH/USD no oracle getPrice("ETH")
Não implementado. O cálculo é fixo: 1 ETH = 1000 HYPE, não consulta o oracle.