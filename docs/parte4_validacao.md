# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

**Objetivo da reunião:** mostrar ao cliente que os dados de fevereiro de 2025 foram carregados por completo e sem alteração, conferir os números com os registros do próprio cliente e decidir, junto com ele, o que fazer com cada inconsistência encontrada na planilha.

**O que levamos:** o banco carregado com a planilha `dados/base_teste.xlsx`, as consultas prontas de `sql/04_validacao.sql` e a lista de erros dos dados (no fim deste documento).

**O que sai da reunião:** os totais de fevereiro aprovados ou corrigidos, uma decisão para cada erro e o aceite formal registrado em ata.

## 1. Pontos a validar

A reunião segue esta ordem, do geral para o detalhe.

### 1.1. A carga está completa (V01)
Tudo o que veio na planilha está no banco: 20 fornecedores, 20 produtos, 29 pedidos de compra, 20 notas de entrada e 33 vendas. Nenhuma linha se perdeu, e nenhum valor foi alterado para "consertar" os dados.

### 1.2. Totais de venda de fevereiro (V02, V03, V05, V06)
| Indicador | Valor no banco |
| --- | --- |
| Vendas | 14, de 07/02/2025 a 28/02/2025 |
| Produtos diferentes | 14 |
| Quantidade vendida | 173,22 |
| Faturamento | R$ 14.093,17 |
| Filial 1 | 13 vendas, R$ 13.545,64 |
| Filial 2 | 1 venda, R$ 547,53 |

**Pergunta ao cliente:** estes totais batem com o relatório de vendas de fevereiro do seu sistema? Para facilitar a conferência, mostramos o total por filial (V03) e por dia (V05).

### 1.3. Vendas por produto (V04)
O faturamento de cada um dos 14 produtos, com o preço praticado e o preço do cadastro lado a lado.

### 1.4. Produtos e filiais que não estão no cadastro (E01, E02)
- 6 vendas de fevereiro são de produtos que **não existem no cadastro** (P22 a P27). Elas somam **R$ 3.241,24, cerca de 23% do faturamento do mês**.
- 1 venda de fevereiro (venda 27, R$ 547,53) é da **filial 2**, que não tem nenhum produto cadastrado.

**Pergunta ao cliente:** esses produtos e essa filial existem? Se sim, precisamos do cadastro para completar a base.

### 1.5. Preços de venda (E05, E06)
- Nenhuma venda de fevereiro de produto cadastrado foi feita pelo preço do cadastro. Exemplo: P16 foi vendido a R$ 14,41, mas o cadastro diz R$ 278,88.
- 3 vendas de fevereiro saíram **abaixo do preço de compra** (P15, P16 e P20).

**Pergunta ao cliente:** qual preço vale, o da venda ou o do cadastro? O cadastro de preços está atualizado?

### 1.6. Quantidades fracionadas (E03)
2 vendas de fevereiro têm quantidade quebrada com unidade "UN": P16 com 37,11 e P26 com 3,11.

**Pergunta ao cliente:** o produto é vendido por peso ou medida (e a unidade está errada), ou a quantidade foi digitada errada?

### 1.7. Compras de fevereiro (V07, V08)
| Indicador | Valor no banco |
| --- | --- |
| Pedidos | 17 |
| Quantidade pedida | 619 |
| Quantidade entregue (segundo o pedido) | 299 |
| Quantidade pendente | 320 |
| Valor dos pedidos | R$ 28.396,93 |

Situação de cada pedido de fevereiro, cruzando com as notas de entrada (V08):

| Situação | Pedidos |
| --- | --- |
| Não recebido | 9 |
| Recebido parcial | 5 |
| Recebido a mais | 3 |

Os 9 "não recebidos" têm **ordem de compra = 0** (E07). Sem a ordem de compra não há como ligar o pedido à nota de entrada.

**Pergunta ao cliente:** qual é a ordem de compra correta desses pedidos? Duas notas (NFE19 e NFE20) chegaram para as ordens 19 e 20, mas os pedidos desses produtos estão com ordem 0 (E12).

### 1.8. Pedidos repetidos (E09)
Os pedidos 21 a 29 repetem o produto e a data dos pedidos 12 a 20, com quantidades menores. Na planilha, essas mesmas 9 linhas têm dados extras em colunas sem título (M a W), que não foram importados.

**Pergunta ao cliente:** os pedidos 21 a 29 são pedidos novos, correções dos pedidos 12 a 20 ou duplicidade de exportação?

### 1.9. Datas fora de ordem (E08, E14)
- 16 dos 17 pedidos de fevereiro têm **data de entrega anterior à data do pedido**.
- 2 notas de fevereiro deram entrada **antes** de o pedido existir.

**Pergunta ao cliente:** o campo `data_entrega` é a data prevista, a data real, ou as datas foram exportadas invertidas?

### 1.10. Recebimentos de fevereiro (V09, E11, E13, E15, E16)
10 notas de entrada em fevereiro, com 468 unidades e R$ 36.722,92 pelo custo da nota.

Em toda a base, o pedido e a nota não conferem entre si:
- a quantidade entregue no pedido difere da quantidade recebida na nota em todos os 18 casos;
- o custo na nota difere do preço do pedido em todos os 18 casos;
- 7 notas trazem mais do que foi pedido.

**Pergunta ao cliente:** qual fonte é a oficial para quantidade e custo recebidos, o pedido ou a nota fiscal?

### 1.11. Fornecedores (E10, E18)
- Em 22 dos 29 pedidos, o fornecedor do pedido é diferente do fornecedor do produto no cadastro.
- 3 fornecedores (F14, F15, F16) não fornecem nenhum produto.

### 1.12. Campos com valor fixo (E19)
Todas as 33 vendas têm horário 08:00:00 e item 1.

**Pergunta ao cliente:** o horário e o número do item são reais, ou são um valor padrão da exportação? Se forem padrão, não dá para separar duas vendas iguais do mesmo dia.

### 1.13. Encerramento
1. Registrar em ata a decisão para cada ponto acima.
2. Aplicar as correções **na origem** (no sistema ou na planilha do cliente), não à mão no banco.
3. Refazer a carga e rodar de novo as consultas V01 a V09.
4. Obter o aceite formal do cliente sobre os números de fevereiro.

## 2. Técnicas para garantir exatidão e precisão

| Técnica | Como foi aplicada | Consultas |
| --- | --- | --- |
| Conferência de contagem | Linhas na planilha x linhas no banco, tabela por tabela | V01 |
| Conciliação com fonte independente | Totais de fevereiro comparados com o relatório do sistema do cliente, no total, por filial e por dia | V02, V03, V05 |
| Soma das partes igual ao total | A soma por produto tem de dar exatamente o total geral (diferença 0) | V06 |
| Mesmo resultado em dois bancos | A carga foi feita no PostgreSQL e no MySQL, e os totais de fevereiro são idênticos nos dois | Parte 1 |
| Integridade referencial | Venda sem produto ou filial cadastrada, nota sem pedido | E01, E02, E12 |
| Regras de domínio | Quantidade quebrada em "UN", venda abaixo do custo, margem negativa | E03, E06, E17 |
| Consistência entre tabelas | Pedido x nota: quantidade, data e custo | E11, E13, E15, E16 |
| Ordem cronológica | Entrega antes do pedido, entrada antes do pedido | E08, E14 |
| Detecção de duplicidade | Pedidos repetidos, mesmo preço em produtos diferentes | E04, E09 |
| Amostragem documental | Escolher algumas notas de fevereiro (por exemplo NFE1, NFE5 e NFE13) e conferir com o documento fiscal (XML ou DANFE) | V08, V09 |
| Tipos de dado corretos | Dinheiro e quantidade em `numeric`, sem arredondamento de ponto flutuante | Parte 1 |
| Rastreabilidade | DDL, importação e consultas estão em scripts versionados no Git; qualquer pessoa refaz a carga e chega aos mesmos números | Todas |
| Registro e aceite | Cada decisão vai para a ata, e a validação só termina com o aceite do cliente | Encerramento |

## 3. Consultas preparadas para a reunião

As consultas estão em `sql/04_validacao.sql`, para PostgreSQL. Rode o arquivo depois de criar as tabelas (`sql/01_ddl_postgres.sql`) e importar a planilha (`scripts/importar.py`). A primeira coluna de cada resultado (`consulta`) traz o código usado neste documento.

| Código | O que mostra | Resultado nesta base |
| --- | --- | --- |
| V01 | Linhas na planilha x linhas no banco, por tabela | 5 tabelas, diferença 0 em todas |
| V02 | Resumo das vendas de fevereiro: vendas, produtos, filiais, quantidade, faturamento, primeira e última venda | 14 vendas, R$ 14.093,17 |
| V03 | Vendas de fevereiro por filial, indicando se a filial está cadastrada | Filial 1: R$ 13.545,64; filial 2 (não cadastrada): R$ 547,53 |
| V04 | Vendas de fevereiro por produto, com preço médio praticado e preço do cadastro | 14 produtos, 6 sem cadastro |
| V05 | Vendas de fevereiro por dia | 6 dias com venda |
| V06 | Total geral x soma por produto | R$ 14.093,17 nos dois, diferença 0 |
| V07 | Resumo dos pedidos de compra de fevereiro | 17 pedidos, 9 com ordem de compra 0 |
| V08 | Situação de cada pedido de fevereiro: não recebido, recebido parcial, recebido a mais ou recebido | 9 não recebidos, 5 parciais, 3 a mais |
| V09 | Resumo das notas de entrada de fevereiro | 10 notas, R$ 36.722,92 |
| E01 a E19 | Uma consulta para cada erro dos dados, listando os registros afetados | Ver a tabela abaixo |

## Erros encontrados nos dados

Quantidades em toda a base; entre parênteses, a parte de fevereiro de 2025 quando se aplica.

| Tabela | Problema | Quantidade | Consulta que mostra |
| --- | --- | --- | --- |
| venda | Produto não existe no cadastro (P21 a P28) | 13 vendas (6 em fev, R$ 3.241,24) | E01 |
| venda | Filial não existe no cadastro (filiais 2 e 3) | 4 vendas: 27, 28, 32 e 33 (1 em fev) | E02 |
| venda | Quantidade fracionada com unidade "UN" | 5 vendas (2 em fev) | E03 |
| venda | Mesmo valor unitário para produtos diferentes (ex.: P13 e P21 a R$ 61,85) | 8 valores em 21 vendas (13 em fev) | E04 |
| venda | Valor unitário diferente do preço de venda do cadastro | 20 de 20 vendas de produtos cadastrados (8 de 8 em fev) | E05 |
| venda | Venda abaixo do preço de compra do cadastro | 7 vendas (3 em fev: P15, P16 e P20) | E06 |
| venda | Horário sempre 08:00:00 e item sempre 1 (provável valor padrão) | 33 de 33 vendas | E19 |
| pedido_compra | `ordem_compra = 0`: pedido sem ligação com nota de entrada | 11 pedidos, 19 a 29 (9 em fev) | E07 |
| pedido_compra | Data de entrega anterior à data do pedido | 20 de 29 pedidos (16 dos 17 de fev) | E08 |
| pedido_compra | Mesmo produto e mesma data em dois pedidos (21 a 29 repetem 12 a 20) | 9 pares | E09 |
| pedido_compra | Fornecedor do pedido diferente do fornecedor do produto no cadastro (considerando que o fornecedor N do pedido é o "FN" do cadastro) | 22 de 29 pedidos | E10 |
| pedido_compra | Quantidade entregue no pedido diferente da quantidade recebida na nota | 18 de 18 pedidos com nota | E11 |
| pedido_compra (planilha) | Dados em 11 colunas sem cabeçalho (M a W), não importados | 9 linhas (pedidos 21 a 29) | Aviso do `scripts/importar.py` (os dados não estão no banco) |
| entradas_mercadoria | Nota sem pedido correspondente (NFE19 e NFE20, ordens 19 e 20) | 2 notas | E12 |
| entradas_mercadoria | Quantidade recebida maior que a pedida | 7 notas | E13 |
| entradas_mercadoria | Entrada antes da data do pedido | 9 notas (2 com entrada em fev) | E14 |
| entradas_mercadoria | Custo na nota diferente do preço do pedido | 18 de 18 notas com pedido | E15 |
| entradas_mercadoria | Data de entrada diferente da data de entrega do pedido | 17 de 18 notas com pedido | E16 |
| produtos_filial | Preço de venda menor que o preço de compra (P1, P8, P15 e P18) | 4 de 20 produtos | E17 |
| fornecedor | Fornecedor sem nenhum produto (F14, F15 e F16), a confirmar com o cliente | 3 de 20 fornecedores | E18 |
