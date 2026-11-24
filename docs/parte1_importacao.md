# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

## Estrutura da planilha

| Aba | Coluna | Tipo | Observação |
| --- | --- | --- | --- |
|  |  |  |  |

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

| Erro | Efeito | Correção |
| --- | --- | --- |
|  |  |  |

## Tratamentos aplicados aos dados

(conversão de tipos, validações, normalizações)

## Conferência final

| Tabela | Linhas na planilha | Linhas no banco |
| --- | --- | --- |
| fornecedor |  |  |
| produtos_filial |  |  |
| pedido_compra |  |  |
| entradas_mercadoria |  |  |
| venda |  |  |
