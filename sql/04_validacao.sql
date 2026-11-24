-- 04_validacao
-- Nome:

SELECT 'V01' AS consulta,
       t.tabela,
       t.linhas_planilha,
       t.linhas_banco,
       t.linhas_banco - t.linhas_planilha AS diferenca
FROM (
    VALUES ('fornecedor',          20, (SELECT COUNT(*) FROM fornecedor)),
           ('produtos_filial',     20, (SELECT COUNT(*) FROM produtos_filial)),
           ('pedido_compra',       29, (SELECT COUNT(*) FROM pedido_compra)),
           ('entradas_mercadoria', 20, (SELECT COUNT(*) FROM entradas_mercadoria)),
           ('venda',               33, (SELECT COUNT(*) FROM venda))
) AS t (tabela, linhas_planilha, linhas_banco);

SELECT 'V02' AS consulta,
       COUNT(*)                                          AS vendas,
       COUNT(DISTINCT produto_id)                        AS produtos,
       COUNT(DISTINCT filial_id)                         AS filiais,
       SUM(qtde_vendida)                                 AS qtde_total,
       ROUND(SUM(qtde_vendida * valor_unitario), 2)      AS valor_total_rs,
       TO_CHAR(MIN(data_emissao), 'DD/MM/YYYY')          AS primeira_venda,
       TO_CHAR(MAX(data_emissao), 'DD/MM/YYYY')          AS ultima_venda
FROM venda
WHERE data_emissao >= DATE '2025-02-01'
  AND data_emissao <  DATE '2025-03-01';

SELECT 'V03' AS consulta,
       v.filial_id,
       CASE WHEN EXISTS (SELECT 1 FROM produtos_filial pf WHERE pf.filial_id = v.filial_id)
            THEN 'sim' ELSE 'não' END                    AS filial_cadastrada,
       COUNT(*)                                          AS vendas,
       SUM(v.qtde_vendida)                               AS qtde_total,
       ROUND(SUM(v.qtde_vendida * v.valor_unitario), 2)  AS valor_total_rs
FROM venda v
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.filial_id
ORDER BY v.filial_id;

SELECT 'V04' AS consulta,
       v.produto_id || COALESCE(' - ' || pf.descricao, '')                  AS produto,
       CASE WHEN pf.produto_id IS NULL THEN 'não' ELSE 'sim' END            AS cadastrado,
       SUM(v.qtde_vendida)                                                  AS qtde_vendida,
       ROUND(SUM(v.qtde_vendida * v.valor_unitario), 2)                     AS valor_total_rs,
       ROUND(SUM(v.qtde_vendida * v.valor_unitario) / SUM(v.qtde_vendida), 2) AS valor_unitario_medio,
       pf.preco_venda                                                       AS preco_venda_cadastro
FROM venda v
LEFT JOIN produtos_filial pf
       ON pf.produto_id = v.produto_id
      AND pf.filial_id  = v.filial_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id, pf.produto_id, pf.descricao, pf.preco_venda
ORDER BY LENGTH(v.produto_id), v.produto_id;

SELECT 'V05' AS consulta,
       TO_CHAR(data_emissao, 'DD/MM/YYYY')               AS dia,
       COUNT(*)                                          AS vendas,
       SUM(qtde_vendida)                                 AS qtde_total,
       ROUND(SUM(qtde_vendida * valor_unitario), 2)      AS valor_total_rs
FROM venda
WHERE data_emissao >= DATE '2025-02-01'
  AND data_emissao <  DATE '2025-03-01'
GROUP BY data_emissao
ORDER BY data_emissao;

SELECT 'V06' AS consulta,
       ROUND(t.total, 2)            AS total_geral_rs,
       ROUND(p.soma, 2)             AS soma_por_produto_rs,
       t.total - p.soma             AS diferenca
FROM (
    SELECT SUM(qtde_vendida * valor_unitario) AS total
    FROM venda
    WHERE data_emissao >= DATE '2025-02-01'
      AND data_emissao <  DATE '2025-03-01'
) t
CROSS JOIN (
    SELECT SUM(valor) AS soma
    FROM (
        SELECT produto_id, SUM(qtde_vendida * valor_unitario) AS valor
        FROM venda
        WHERE data_emissao >= DATE '2025-02-01'
          AND data_emissao <  DATE '2025-03-01'
        GROUP BY produto_id
    ) por_produto
) p;

SELECT 'V07' AS consulta,
       COUNT(*)                                          AS pedidos,
       COUNT(*) FILTER (WHERE ordem_compra = 0)          AS pedidos_sem_ordem_compra,
       SUM(qtde_pedida)                                  AS qtde_pedida,
       SUM(qtde_entregue)                                AS qtde_entregue,
       SUM(qtde_pendente)                                AS qtde_pendente,
       ROUND(SUM(qtde_pedida * preco_compra), 2)         AS valor_pedido_rs
FROM pedido_compra
WHERE data_pedido >= DATE '2025-02-01'
  AND data_pedido <  DATE '2025-03-01';

SELECT 'V08' AS consulta,
       p.pedido_id,
       p.produto_id || COALESCE(' - ' || p.descricao_produto, '')  AS produto,
       p.ordem_compra,
       TO_CHAR(p.data_pedido, 'DD/MM/YYYY')                        AS data_pedido,
       p.qtde_pedida,
       e.nro_nfe,
       TO_CHAR(e.data_entrada, 'DD/MM/YYYY')                       AS data_entrada,
       e.qtde_recebida,
       CASE
           WHEN e.nro_nfe IS NULL                THEN 'não recebido'
           WHEN e.qtde_recebida < p.qtde_pedida  THEN 'recebido parcial'
           WHEN e.qtde_recebida > p.qtde_pedida  THEN 'recebido a mais'
           ELSE 'recebido'
       END                                                         AS situacao
FROM pedido_compra p
LEFT JOIN entradas_mercadoria e
       ON e.ordem_compra = p.ordem_compra
      AND e.produto_id   = p.produto_id
WHERE p.data_pedido >= DATE '2025-02-01'
  AND p.data_pedido <  DATE '2025-03-01'
ORDER BY p.pedido_id;

SELECT 'V09' AS consulta,
       COUNT(*)                                          AS notas_fiscais,
       SUM(qtde_recebida)                                AS qtde_recebida,
       ROUND(SUM(qtde_recebida * custo_unitario), 2)     AS valor_recebido_rs
FROM entradas_mercadoria
WHERE data_entrada >= DATE '2025-02-01'
  AND data_entrada <  DATE '2025-03-01';

SELECT 'E01' AS consulta,
       v.venda_id,
       v.produto_id,
       v.filial_id,
       TO_CHAR(v.data_emissao, 'DD/MM/YYYY') AS data_emissao
FROM venda v
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial pf WHERE pf.produto_id = v.produto_id)
ORDER BY v.venda_id;

SELECT 'E02' AS consulta,
       v.venda_id,
       v.produto_id,
       v.filial_id,
       TO_CHAR(v.data_emissao, 'DD/MM/YYYY') AS data_emissao
FROM venda v
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial pf WHERE pf.filial_id = v.filial_id)
ORDER BY v.venda_id;

SELECT 'E03' AS consulta,
       venda_id,
       produto_id,
       qtde_vendida,
       unidade_medida,
       TO_CHAR(data_emissao, 'DD/MM/YYYY') AS data_emissao
FROM venda
WHERE unidade_medida = 'UN'
  AND qtde_vendida <> TRUNC(qtde_vendida)
ORDER BY venda_id;

SELECT 'E04' AS consulta,
       valor_unitario,
       STRING_AGG(DISTINCT produto_id, ', ') AS produtos,
       COUNT(*)                              AS vendas
FROM venda
GROUP BY valor_unitario
HAVING COUNT(DISTINCT produto_id) > 1
ORDER BY valor_unitario;

SELECT 'E05' AS consulta,
       v.venda_id,
       v.produto_id,
       v.valor_unitario,
       pf.preco_venda                     AS preco_venda_cadastro,
       v.valor_unitario - pf.preco_venda  AS diferenca
FROM venda v
JOIN produtos_filial pf
  ON pf.produto_id = v.produto_id
 AND pf.filial_id  = v.filial_id
WHERE v.valor_unitario <> pf.preco_venda
ORDER BY v.venda_id;

SELECT 'E06' AS consulta,
       v.venda_id,
       v.produto_id,
       v.valor_unitario,
       pf.preco_compra                    AS preco_compra_cadastro
FROM venda v
JOIN produtos_filial pf
  ON pf.produto_id = v.produto_id
 AND pf.filial_id  = v.filial_id
WHERE v.valor_unitario < pf.preco_compra
ORDER BY v.venda_id;

SELECT 'E07' AS consulta,
       pedido_id,
       produto_id,
       ordem_compra,
       TO_CHAR(data_pedido, 'DD/MM/YYYY') AS data_pedido,
       qtde_pedida
FROM pedido_compra
WHERE ordem_compra = 0
ORDER BY pedido_id;

SELECT 'E08' AS consulta,
       pedido_id,
       produto_id,
       TO_CHAR(data_pedido, 'DD/MM/YYYY')  AS data_pedido,
       TO_CHAR(data_entrega, 'DD/MM/YYYY') AS data_entrega,
       data_pedido - data_entrega          AS dias_antes
FROM pedido_compra
WHERE data_entrega < data_pedido
ORDER BY pedido_id;

SELECT 'E09' AS consulta,
       produto_id,
       TO_CHAR(data_pedido, 'DD/MM/YYYY')                     AS data_pedido,
       STRING_AGG(pedido_id::text, ', ' ORDER BY pedido_id)   AS pedidos,
       STRING_AGG(qtde_pedida::text, ', ' ORDER BY pedido_id) AS qtdes_pedidas
FROM pedido_compra
GROUP BY produto_id, data_pedido
HAVING COUNT(*) > 1
ORDER BY LENGTH(produto_id), produto_id;

SELECT 'E10' AS consulta,
       p.pedido_id,
       p.produto_id,
       p.fornecedor_id    AS fornecedor_no_pedido,
       pf.idfornecedor    AS fornecedor_no_cadastro
FROM pedido_compra p
JOIN produtos_filial pf
  ON pf.produto_id = p.produto_id
 AND pf.filial_id  = p.filial_id
WHERE 'F' || p.fornecedor_id::text <> pf.idfornecedor
ORDER BY p.pedido_id;

SELECT 'E11' AS consulta,
       p.pedido_id,
       p.produto_id,
       p.qtde_pedida,
       p.qtde_entregue      AS qtde_entregue_no_pedido,
       e.nro_nfe,
       e.qtde_recebida      AS qtde_recebida_na_nota
FROM pedido_compra p
JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra
 AND e.produto_id   = p.produto_id
WHERE p.qtde_entregue <> e.qtde_recebida
ORDER BY p.pedido_id;

SELECT 'E12' AS consulta,
       e.nro_nfe,
       e.ordem_compra,
       e.produto_id,
       TO_CHAR(e.data_entrada, 'DD/MM/YYYY') AS data_entrada,
       e.qtde_recebida
FROM entradas_mercadoria e
WHERE NOT EXISTS (
        SELECT 1
        FROM pedido_compra p
        WHERE p.ordem_compra = e.ordem_compra
          AND p.produto_id   = e.produto_id
      )
ORDER BY e.ordem_compra;

SELECT 'E13' AS consulta,
       e.nro_nfe,
       p.pedido_id,
       p.produto_id,
       p.qtde_pedida,
       e.qtde_recebida,
       e.qtde_recebida - p.qtde_pedida AS recebido_a_mais
FROM pedido_compra p
JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra
 AND e.produto_id   = p.produto_id
WHERE e.qtde_recebida > p.qtde_pedida
ORDER BY p.pedido_id;

SELECT 'E14' AS consulta,
       e.nro_nfe,
       p.pedido_id,
       p.produto_id,
       TO_CHAR(p.data_pedido, 'DD/MM/YYYY')  AS data_pedido,
       TO_CHAR(e.data_entrada, 'DD/MM/YYYY') AS data_entrada
FROM pedido_compra p
JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra
 AND e.produto_id   = p.produto_id
WHERE e.data_entrada < p.data_pedido
ORDER BY p.pedido_id;

SELECT 'E15' AS consulta,
       e.nro_nfe,
       p.pedido_id,
       p.produto_id,
       p.preco_compra                     AS preco_no_pedido,
       e.custo_unitario                   AS custo_na_nota,
       e.custo_unitario - p.preco_compra  AS diferenca
FROM pedido_compra p
JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra
 AND e.produto_id   = p.produto_id
WHERE e.custo_unitario <> p.preco_compra
ORDER BY p.pedido_id;

SELECT 'E16' AS consulta,
       e.nro_nfe,
       p.pedido_id,
       p.produto_id,
       TO_CHAR(p.data_entrega, 'DD/MM/YYYY') AS data_entrega_no_pedido,
       TO_CHAR(e.data_entrada, 'DD/MM/YYYY') AS data_entrada_na_nota
FROM pedido_compra p
JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra
 AND e.produto_id   = p.produto_id
WHERE e.data_entrada <> p.data_entrega
ORDER BY p.pedido_id;

SELECT 'E17' AS consulta,
       filial_id,
       produto_id,
       preco_compra,
       preco_venda,
       preco_venda - preco_compra AS margem
FROM produtos_filial
WHERE preco_venda < preco_compra
ORDER BY LENGTH(produto_id), produto_id;

SELECT 'E18' AS consulta,
       f.idfornecedor,
       f.razao_social
FROM fornecedor f
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial pf WHERE pf.idfornecedor = f.idfornecedor)
ORDER BY LENGTH(f.idfornecedor), f.idfornecedor;

SELECT 'E19' AS consulta,
       COUNT(*)                     AS vendas,
       COUNT(DISTINCT horariomov)   AS horarios_distintos,
       MIN(horariomov)              AS horario,
       COUNT(DISTINCT item)         AS itens_distintos,
       MIN(item)                    AS item
FROM venda;
