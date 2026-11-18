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

Erros encontrados lendo o DDL (a coluna Correção é preenchida no passo 2):

| Tabela | Erro | Correção |
| --- | --- | --- |
| entradas_mercadoria | A PK usa `ordem_compra`, mas a coluna não foi declarada. A tabela não é criada |  |
| produtos_filial | Falta vírgula depois de `idfonecedor int4 NULL`. A tabela não é criada |  |
| produtos_filial | A PK usa `idproduto`, mas a coluna se chama `produto_id` |  |
| produtos_filial | Typos nos nomes das colunas: `decricao` e `idfonecedor` |  |
| produtos_filial | `filial_id` aceita NULL e faz parte da PK |  |
| produtos_filial | `idfornecedor int4`, mas a planilha e a tabela fornecedor usam texto ("F8") |  |
| produtos_filial | `produto_id varchar(255)`, enquanto nas outras tabelas é `varchar(25)` |  |
| fornecedor | Typo em `idforncedor` |  |
| fornecedor | A PK usa `idproduto`, coluna que não existe nesta tabela. A tabela não é criada |  |
| pedido_compra | `pedido_id`, `item` e `ordem_compra` são `float8`: identificador não pode ser ponto flutuante |  |
| pedido_compra | `fornecedor_id DEFAULT 0` aponta para um fornecedor que não existe |  |
| venda | A PK se chama `pk_consumo`, nome de outra tabela |  |
| venda | `produto_id DEFAULT ''` permite produto vazio dentro da PK |  |
| venda | `filial_id int8`, enquanto nas outras tabelas é `int4` |  |
| Todas | Quantidades, estoque e preços em `float8` (impreciso para dinheiro) e `DEFAULT '0'` entre aspas em coluna numérica |  |
| Todas | `int8`, `float8`, `public.` e `::character varying` não existem no MySQL |  |

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
