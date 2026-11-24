# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

- **Importação:** script Python `scripts/importar.py` (versão corrigida), com **pandas** e **openpyxl** para ler a planilha.
- **Gravação no banco:** **psycopg2** para PostgreSQL e **mysql-connector-python** para MySQL.
- **Bancos:** PostgreSQL 16 e MySQL 8.4, rodando localmente em contêineres Docker.
- **Criação das tabelas:** `sql/01_ddl_postgres.sql` e `sql/01_ddl_mysql.sql`, executados antes da importação.

Dependências:

```
pip install pandas openpyxl psycopg2-binary mysql-connector-python
```

Como rodar (a partir da raiz do repositório, com as tabelas já criadas):

```
DB_PASSWORD=<senha> python scripts/importar.py                # PostgreSQL
DB_PASSWORD=<senha> python scripts/importar.py --sgbd mysql   # MySQL
```

| Variável de ambiente | Padrão |
| --- | --- |
| `DB_PASSWORD` | obrigatória (a senha não fica no código) |
| `DB_HOST` | `localhost` |
| `DB_PORT` | `5432` (PostgreSQL) ou `3306` (MySQL) |
| `DB_NAME` | `postgres` |
| `DB_USER` | `postgres` (PostgreSQL) ou `root` (MySQL) |
| `ARQUIVO_XLSX` | `dados/base_teste.xlsx` |

## Estrutura da planilha

A planilha `dados/base_teste.xlsx` tem 5 abas. Todas declaram o intervalo até a linha 1000, mas só as primeiras linhas têm dados: **venda 33, pedido_compra 29, entradas_mercadoria 20, produtos_filial 20 e fornecedor 20**. As datas estão gravadas como data do Excel, e o pandas as lê como `datetime64`.

| Aba | Coluna | Tipo | Observação |
| --- | --- | --- | --- |
| venda | venda_id | inteiro | 1 a 33, sem repetição |
| venda | data_emissao | data | Janeiro a março de 2025 (14 vendas em fevereiro) |
| venda | horariomov | texto | Sempre "08:00:00" |
| venda | produto_id | texto | P1 a P28; P21 a P28 não existem em produtos_filial |
| venda | qtde_vendida | decimal | 5 valores fracionados (38,6; 20,04; 2,86; 37,11; 3,11) com unidade "UN" |
| venda | valor_unitario | decimal | 8 pares de produtos diferentes com o mesmo valor (ex.: P13 e P21 a 61,85) |
| venda | filial_id | inteiro | 1, 2 e 3; as filiais 2 e 3 não existem em produtos_filial |
| venda | item | inteiro | Sempre 1 |
| venda | unidade_medida | texto | Sempre "UN" |
| pedido_compra | pedido_id | inteiro | 1 a 29 |
| pedido_compra | data_pedido | data | Janeiro a março de 2025 |
| pedido_compra | item | inteiro | Sempre 1 |
| pedido_compra | produto_id | texto | P1 a P20; P12 a P20 aparecem em dois pedidos |
| pedido_compra | descricao_produto | texto | "Produto N" |
| pedido_compra | ordem_compra | inteiro | Liga o pedido à entrada; **0 nos pedidos 19 a 29** |
| pedido_compra | qtde_pedida | número | |
| pedido_compra | filial_id | inteiro | Sempre 1 |
| pedido_compra | data_entrega | data | Em 20 dos 29 pedidos é anterior à data_pedido |
| pedido_compra | qtde_entregue | número | 0 nos pedidos 19 a 29 |
| pedido_compra | preco_compra | decimal | |
| pedido_compra | fornecedor_id | inteiro | 1 a 20, enquanto fornecedor usa texto ("F1" a "F20") |
| pedido_compra | (colunas M a W) | sem cabeçalho | 11 colunas com dados só nas linhas 22 a 30 (pedidos 21 a 29) |
| pedido_compra | qtde_pendente | não existe | Coluna do DDL que não está na planilha; é calculada na importação |
| entradas_mercadoria | data_entrada | data | Em 9 entradas é anterior à data do pedido |
| entradas_mercadoria | nro_nfe | texto | NFE1 a NFE20 |
| entradas_mercadoria | item | inteiro | Sempre 1 |
| entradas_mercadoria | produto_id | texto | P1 a P20 |
| entradas_mercadoria | descricao_produto | texto | "Produto N" |
| entradas_mercadoria | ordem_compra | inteiro | 1 a 20; as ordens 19 e 20 não batem com nenhum pedido (que estão com 0) |
| entradas_mercadoria | qtde_recebida | número | Em 7 entradas é maior que a quantidade pedida |
| entradas_mercadoria | filial_id | inteiro | Sempre 1 |
| entradas_mercadoria | custo_unitario | decimal | Diferente do preco_compra do pedido em 18 de 20 casos |
| produtos_filial | filial_id | inteiro | Sempre 1 |
| produtos_filial | idproduto | texto | P1 a P20; no DDL a coluna se chama `produto_id` |
| produtos_filial | descricao | texto | "Produto N" |
| produtos_filial | estoque | número | |
| produtos_filial | preco_unitario | decimal | |
| produtos_filial | preco_compra | decimal | |
| produtos_filial | preco_venda | decimal | Em 4 produtos é menor que o preco_compra |
| produtos_filial | idfornecedor | texto | "F1" a "F20"; o DDL original declarava `int4` |
| fornecedor | idfornecedor | texto | "F1" a "F20" |
| fornecedor | razao_social | texto | "Fornecedor N LTDA" |

## Erros encontrados no DDL e como foram corrigidos

Ao rodar `sql/01_ddl_enunciado.sql` em um PostgreSQL 16 limpo, **3 das 5 tabelas não são criadas**. Só `venda` e `pedido_compra` existem depois da execução.

Mensagens do PostgreSQL:

| Tabela | Mensagem do PostgreSQL |
| --- | --- |
| entradas_mercadoria | `column "ordem_compra" named in key does not exist` |
| produtos_filial | `syntax error at or near "("` |
| fornecedor | `column "idproduto" named in key does not exist` |

Erros encontrados lendo o DDL e a correção aplicada em `sql/01_ddl_postgres.sql` e `sql/01_ddl_mysql.sql`:

| Tabela | Erro | Correção |
| --- | --- | --- |
| entradas_mercadoria | A PK usa `ordem_compra`, mas a coluna não foi declarada. A tabela não é criada | Coluna `ordem_compra int8 NOT NULL` adicionada |
| produtos_filial | Falta vírgula depois de `idfonecedor int4 NULL`. A tabela não é criada | Vírgula adicionada |
| produtos_filial | A PK usa `idproduto`, mas a coluna se chama `produto_id` | PK `(filial_id, produto_id)` |
| produtos_filial | Typos nos nomes das colunas: `decricao` e `idfonecedor` | `descricao` e `idfornecedor` |
| produtos_filial | `filial_id` aceita NULL e faz parte da PK | `filial_id int4 NOT NULL` |
| produtos_filial | `idfornecedor int4`, mas a planilha e a tabela fornecedor usam texto ("F8") | `idfornecedor varchar(25)` com FK para `fornecedor` |
| produtos_filial | `produto_id varchar(255)`, enquanto nas outras tabelas é `varchar(25)` | `varchar(25)` |
| fornecedor | Typo em `idforncedor` | `idfornecedor` |
| fornecedor | A PK usa `idproduto`, coluna que não existe nesta tabela. A tabela não é criada | PK só em `idfornecedor` |
| pedido_compra | `pedido_id`, `item` e `ordem_compra` são `float8`: identificador não pode ser ponto flutuante | `pedido_id` e `ordem_compra` em `int8`, `item` em `int4` |
| pedido_compra | `fornecedor_id DEFAULT 0` aponta para um fornecedor que não existe | Sem default, aceita NULL |
| venda | A PK se chama `pk_consumo`, nome de outra tabela | `pk_venda` |
| venda | `produto_id DEFAULT ''` permite produto vazio dentro da PK | Sem default, continua `NOT NULL` |
| venda | `filial_id int8`, enquanto nas outras tabelas é `int4` | `int4` |
| Todas | Quantidades, estoque e preços em `float8` (impreciso para dinheiro) e `DEFAULT '0'` entre aspas em coluna numérica | `numeric(14,3)` para quantidades e estoque, `numeric(12,4)` para preços, `DEFAULT 0` sem aspas |
| Todas | `int8`, `float8`, `public.` e `::character varying` não existem no MySQL | Na versão MySQL: `BIGINT`, `INT`, `DECIMAL`, sem prefixo `public.` e sem o cast |

Decisões de projeto:
- **Sem FK de `venda` para `produtos_filial`.** A planilha tem vendas de produtos (P21 a P28) e de filiais (2 e 3) que não existem no cadastro. Uma FK impediria a carga, e esses casos são listados como erro de dados na Parte 4.
- **`pedido_compra.fornecedor_id` continua `int4`, sem FK.** A planilha traz números (1 a 20), mas `fornecedor.idfornecedor` é texto ("F1" a "F20"), então as duas colunas não se ligam diretamente.

Resultado: os dois scripts criam as 5 tabelas sem erro, no PostgreSQL 16 e no MySQL 8.4.

## Erros encontrados no script de importação e como foram corrigidos

O `importar.py` original foi rodado, só com a porta de conexão trocada, em um PostgreSQL limpo, em dois cenários. Depois as linhas foram contadas no banco com `SELECT COUNT(*)`:

| Cenário | Mensagem final do script | Linhas que realmente entraram no banco |
| --- | --- | --- |
| Com o DDL original | "20 registros inseridos" em cada aba e "Importação concluída com sucesso!" | fornecedor 0, produtos_filial 0, entradas_mercadoria 0, venda 0, pedido_compra 29 (**todas as datas em NULL**) |
| Com o DDL corrigido | "20 registros inseridos" em cada aba e "Importação concluída com sucesso!" | fornecedor 20, produtos_filial 20, pedido_compra 29, entradas_mercadoria 20, **venda 0**; **todas as datas** de pedido_compra (29) e entradas_mercadoria (20) em NULL |

Erros que aparecem na saída do script original:
- Com o DDL original: `relation "public.fornecedor" does not exist`, e o mesmo erro para produtos_filial e entradas_mercadoria, 20 vezes cada.
- Nos dois cenários: `null value in column "data_emissao" of relation "venda" violates not-null constraint`, 33 vezes, uma para cada venda.

| Erro | Efeito | Correção |
| --- | --- | --- |
| `excel_para_data()` faz `int(valor)`, mas o pandas já entrega a data como `datetime64`; o `except:` vazio engole o erro e devolve `None` | **Todas as datas viram NULL** em silêncio: 29 pedidos e 20 entradas. Em `venda` a data é `NOT NULL`, então as 33 linhas falham | Função `para_data()` aceita data do pandas, número serial do Excel e texto, e **rejeita** o valor que não entende, sem `except:` genérico |
| Imprime `len(df)` como "registros inseridos" (exceto em pedido_compra) | Diz "20 registros inseridos" com 0 linhas no banco, e "sucesso" com a tabela venda vazia | Conta as linhas no banco com `SELECT COUNT(*)`, compara com a planilha e sai com código de erro se divergir |
| `conn.rollback()` dentro do loop, com `commit()` só no fim da aba | Uma linha com erro desfaz **todas as anteriores** da mesma aba | Uma transação por aba, com `SAVEPOINT` por linha no PostgreSQL: só a linha ruim é descartada |
| `ON CONFLICT ... DO NOTHING` | Linha duplicada some sem aviso | `INSERT` simples: a duplicata aparece como linha rejeitada, com o número da linha na planilha |
| Usa os nomes `descricao`, `idfornecedor` e `ordem_compra`, que o DDL original grafa errado ou não declara | Com o DDL original, 3 das 5 abas falham por completo | Nomes alinhados ao DDL corrigido; `idproduto` da planilha é renomeado para `produto_id` |
| `df.iloc[:, :12]` em pedido_compra | Descarta em silêncio as colunas M a W, que têm dados em 9 linhas | O script emite um **aviso** com as linhas afetadas e com os pedidos de `ordem_compra = 0`; os dados não são alterados |
| Não descarta as linhas vazias da planilha | Depende do pandas para ignorar o intervalo até a linha 1000 | `dropna(how="all")` remove as linhas totalmente vazias |
| Senha `1234` escrita no código | Viola a regra do README | Senha pela variável de ambiente `DB_PASSWORD`; o script para se ela não estiver definida |
| Só funciona com PostgreSQL; o comentário diz "MySQL 3006" | Não serve para a versão MySQL, e a porta está errada (o certo é 3306) | Opção `--sgbd mysql`, com porta padrão 3306 |

## Tratamentos aplicados aos dados

- **Datas:** data do pandas, número serial do Excel ou texto são convertidos para `date`. Uma data ilegível rejeita a linha, em vez de virar NULL.
- **Inteiros:** identificadores (`venda_id`, `pedido_id`, `item`, `ordem_compra`, `filial_id` e `fornecedor_id`) são convertidos para inteiro. Um valor fracionado rejeita a linha.
- **Textos:** espaços nas pontas removidos com `strip()`.
- **Decimais:** quantidades e preços gravados como `numeric`/`DECIMAL`, sem arredondamento.
- **Nulos:** `horariomov` vazio recebe `'00:00:00'`, como no DDL.
- **Linhas em branco:** removidas antes da importação.
- **Nomes de coluna:** espaços removidos dos cabeçalhos; `idproduto` (planilha) vira `produto_id` (banco).
- **`qtde_pendente`:** calculada como `qtde_pedida - qtde_entregue`, porque a planilha não tem essa coluna.
- **Validação:** cada linha recusada pelo banco (chave duplicada, tipo inválido) é listada com o número da linha da planilha e o motivo.
- **Sem correções por conta própria nos valores.** Os problemas dos dados (por exemplo `ordem_compra = 0` nos pedidos 19 a 29 e as colunas M a W) são **avisados** pelo script e tratados na Parte 4 (`docs/parte4_validacao.md`).

## Conferência final

Importação limpa em cada banco, com as contagens feitas pelo próprio script (`SELECT COUNT(*)`):

| Tabela | Linhas na planilha | Linhas no banco (PostgreSQL) | Linhas no banco (MySQL) |
| --- | --- | --- | --- |
| fornecedor | 20 | 20 | 20 |
| produtos_filial | 20 | 20 | 20 |
| pedido_compra | 29 | 29 | 29 |
| entradas_mercadoria | 20 | 20 | 20 |
| venda | 33 | 33 | 33 |

Conferência do conteúdo, além da contagem:
- **Datas:** nenhuma data nula em `venda`, `pedido_compra` e `entradas_mercadoria`.
- **Amostras contra a planilha:** venda 1 (2025-01-11, P1, 5 un., R$ 78,93), venda 4 (38,6 un.) e pedido 1 (pedido em 2025-01-02, entrega em 2025-02-27, pendente 86).
- **Vendas de fevereiro de 2025:** 14 linhas, quantidade total 173,220 e valor total R$ 14.093,1704. Os números são **idênticos** no PostgreSQL e no MySQL.
- **Segunda execução sem recriar as tabelas:** todas as linhas são rejeitadas como duplicadas, e o script avisa que há divergência, em vez de dizer "sucesso".
