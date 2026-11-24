-- 02_consultas
-- Nome:

SELECT v.produto_id                                       AS produto,
       SUM(v.qtde_vendida)                                AS qtde_vendida,
       ROUND(SUM(v.qtde_vendida * v.valor_unitario), 2)   AS valor_total_rs
FROM venda v
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY valor_total_rs DESC;

SELECT p.produto_id,
       p.descricao_produto,
       p.pedido_id,
       p.ordem_compra,
       p.data_pedido,
       p.qtde_pedida
FROM pedido_compra p
WHERE NOT EXISTS (
        SELECT 1
        FROM entradas_mercadoria e
        WHERE e.ordem_compra = p.ordem_compra
          AND e.produto_id   = p.produto_id
      )
ORDER BY LENGTH(p.produto_id), p.produto_id, p.pedido_id;
