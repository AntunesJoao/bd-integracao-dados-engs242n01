DROP TABLE IF EXISTS venda;
DROP TABLE IF EXISTS entradas_mercadoria;
DROP TABLE IF EXISTS pedido_compra;
DROP TABLE IF EXISTS produtos_filial;
DROP TABLE IF EXISTS fornecedor;

CREATE TABLE fornecedor (
    idfornecedor  VARCHAR(25)  NOT NULL,
    razao_social  VARCHAR(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE produtos_filial (
    filial_id       INT            NOT NULL,
    produto_id      VARCHAR(25)    NOT NULL,
    descricao       VARCHAR(255)   NOT NULL,
    estoque         DECIMAL(14, 3) NOT NULL DEFAULT 0,
    preco_unitario  DECIMAL(12, 4) NOT NULL DEFAULT 0,
    preco_compra    DECIMAL(12, 4) NOT NULL DEFAULT 0,
    preco_venda     DECIMAL(12, 4) NOT NULL DEFAULT 0,
    idfornecedor    VARCHAR(25)    NULL,
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT produtos_filial_fornecedor_fkey
        FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE pedido_compra (
    pedido_id          BIGINT         NOT NULL,
    data_pedido        DATE           NULL,
    item               INT            NOT NULL DEFAULT 0,
    produto_id         VARCHAR(25)    NOT NULL,
    descricao_produto  VARCHAR(255)   NULL,
    ordem_compra       BIGINT         NOT NULL DEFAULT 0,
    qtde_pedida        DECIMAL(14, 3) NULL,
    filial_id          INT            NULL,
    data_entrega       DATE           NULL,
    qtde_entregue      DECIMAL(14, 3) NOT NULL DEFAULT 0,
    qtde_pendente      DECIMAL(14, 3) NOT NULL DEFAULT 0,
    preco_compra       DECIMAL(12, 4) NULL DEFAULT 0,
    fornecedor_id      INT            NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item)
) ENGINE=InnoDB;

CREATE TABLE entradas_mercadoria (
    data_entrada       DATE           NULL,
    nro_nfe            VARCHAR(255)   NOT NULL,
    item               INT            NOT NULL DEFAULT 0,
    produto_id         VARCHAR(25)    NOT NULL,
    descricao_produto  VARCHAR(255)   NULL,
    ordem_compra       BIGINT         NOT NULL DEFAULT 0,
    qtde_recebida      DECIMAL(14, 3) NULL,
    filial_id          INT            NULL,
    custo_unitario     DECIMAL(12, 4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
) ENGINE=InnoDB;

CREATE TABLE venda (
    venda_id        BIGINT         NOT NULL,
    data_emissao    DATE           NOT NULL,
    horariomov      VARCHAR(8)     NOT NULL DEFAULT '00:00:00',
    produto_id      VARCHAR(25)    NOT NULL,
    qtde_vendida    DECIMAL(14, 3) NULL,
    valor_unitario  DECIMAL(12, 4) NOT NULL DEFAULT 0,
    filial_id       INT            NOT NULL DEFAULT 1,
    item            INT            NOT NULL DEFAULT 0,
    unidade_medida  VARCHAR(3)     NULL,
    CONSTRAINT pk_venda PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
) ENGINE=InnoDB;
