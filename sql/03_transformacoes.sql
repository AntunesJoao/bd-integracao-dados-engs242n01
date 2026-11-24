-- 03_transformacoes
-- Nome:

-- Interpretação de "mais de 10 vezes": produto cuja quantidade total requisitada (soma de qtde_pedida)
-- no período passa de 10 unidades. O resultado esperado do enunciado traz "Qtde Requisitada" como
-- quantidade (15), por isso o filtro usa a soma das quantidades. Pela contagem de pedidos nenhum produto
-- passaria do filtro: na base, cada produto tem no máximo 2 pedidos.
-- Período: 01/01/2025 a 31/03/2025, todo o intervalo de datas da base.
WITH requisitados AS (
    SELECT produto_id
    FROM pedido_compra
    WHERE data_pedido BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
    GROUP BY produto_id
    HAVING SUM(qtde_pedida) > 10
)
SELECT p.produto_id || COALESCE(' - ' || p.descricao_produto, '')   AS "Produto",
       SUM(p.qtde_pedida)                                           AS "Qtde Requisitada",
       TO_CHAR(p.data_pedido, 'DD/MM/YYYY')                         AS "Data Solicitação"
FROM pedido_compra p
JOIN requisitados r ON r.produto_id = p.produto_id
WHERE p.data_pedido BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
GROUP BY p.produto_id, p.descricao_produto, p.data_pedido
ORDER BY LENGTH(p.produto_id), p.produto_id, p.data_pedido;

SELECT v.produto_id || COALESCE(' - ' || pf.descricao, '')   AS "Produto",
       v.qtde_vendida                                        AS "Qtde Vendida",
       TO_CHAR(v.data_emissao, 'DD/MM/YYYY')                 AS "Data Venda"
FROM venda v
LEFT JOIN produtos_filial pf
       ON pf.produto_id = v.produto_id
      AND pf.filial_id  = v.filial_id
ORDER BY v.data_emissao, v.venda_id;

SELECT pf.filial_id,
       pf.produto_id || COALESCE(' - ' || pf.descricao, '')   AS "Produto",
       pf.estoque,
       pf.preco_venda,
       pf.idfornecedor
FROM produtos_filial pf
ORDER BY pf.filial_id, LENGTH(pf.produto_id), pf.produto_id;

ALTER TABLE fornecedor ADD COLUMN IF NOT EXISTS idfornecedor_num integer;

UPDATE fornecedor
SET idfornecedor_num = CAST(SUBSTRING(idfornecedor FROM '[0-9]+') AS integer)
WHERE idfornecedor_num IS NULL;

CREATE SEQUENCE IF NOT EXISTS fornecedor_idfornecedor_num_seq OWNED BY fornecedor.idfornecedor_num;

SELECT SETVAL('fornecedor_idfornecedor_num_seq',
              COALESCE((SELECT MAX(idfornecedor_num) FROM fornecedor), 0) + 1,
              false);

UPDATE fornecedor
SET idfornecedor_num = NEXTVAL('fornecedor_idfornecedor_num_seq')
WHERE idfornecedor_num IS NULL;

ALTER TABLE fornecedor ALTER COLUMN idfornecedor_num SET DEFAULT NEXTVAL('fornecedor_idfornecedor_num_seq');
ALTER TABLE fornecedor ALTER COLUMN idfornecedor_num SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS fornecedor_idfornecedor_num_uk ON fornecedor (idfornecedor_num);

ALTER TABLE produtos_filial
    ADD COLUMN IF NOT EXISTS idfornecedor_num integer REFERENCES fornecedor (idfornecedor_num);

CREATE OR REPLACE FUNCTION fn_produtos_filial_idfornecedor_num()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        NEW.idfornecedor_num := NULL;
    ELSE
        SELECT f.idfornecedor_num
        INTO NEW.idfornecedor_num
        FROM fornecedor f
        WHERE f.idfornecedor = NEW.idfornecedor;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Fornecedor % não cadastrado na tabela fornecedor', NEW.idfornecedor;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_produtos_filial_idfornecedor_num ON produtos_filial;

CREATE TRIGGER trg_produtos_filial_idfornecedor_num
BEFORE INSERT OR UPDATE OF idfornecedor ON produtos_filial
FOR EACH ROW
EXECUTE FUNCTION fn_produtos_filial_idfornecedor_num();

UPDATE produtos_filial SET idfornecedor = idfornecedor;

SELECT pf.produto_id,
       pf.idfornecedor,
       pf.idfornecedor_num,
       f.razao_social
FROM produtos_filial pf
JOIN fornecedor f ON f.idfornecedor_num = pf.idfornecedor_num
ORDER BY LENGTH(pf.produto_id), pf.produto_id;

BEGIN;

INSERT INTO produtos_filial (filial_id, produto_id, descricao, idfornecedor)
VALUES (1, 'P21', 'Produto 21', 'F14');

SELECT pf.produto_id,
       pf.idfornecedor,
       pf.idfornecedor_num,
       f.razao_social
FROM produtos_filial pf
JOIN fornecedor f ON f.idfornecedor_num = pf.idfornecedor_num
WHERE pf.produto_id = 'P21';

ROLLBACK;
