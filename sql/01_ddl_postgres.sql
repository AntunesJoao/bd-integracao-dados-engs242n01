DROP TABLE IF EXISTS public.venda;
DROP TABLE IF EXISTS public.entradas_mercadoria;
DROP TABLE IF EXISTS public.pedido_compra;
DROP TABLE IF EXISTS public.produtos_filial;
DROP TABLE IF EXISTS public.fornecedor;

CREATE TABLE public.fornecedor (
    idfornecedor  varchar(25)  NOT NULL,
    razao_social  varchar(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

CREATE TABLE public.produtos_filial (
    filial_id       int4           NOT NULL,
    produto_id      varchar(25)    NOT NULL,
    descricao       varchar(255)   NOT NULL,
    estoque         numeric(14, 3) NOT NULL DEFAULT 0,
    preco_unitario  numeric(12, 4) NOT NULL DEFAULT 0,
    preco_compra    numeric(12, 4) NOT NULL DEFAULT 0,
    preco_venda     numeric(12, 4) NOT NULL DEFAULT 0,
    idfornecedor    varchar(25)    NULL,
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT produtos_filial_fornecedor_fkey
        FOREIGN KEY (idfornecedor) REFERENCES public.fornecedor (idfornecedor)
);

CREATE TABLE public.pedido_compra (
    pedido_id          int8           NOT NULL,
    data_pedido        date           NULL,
    item               int4           NOT NULL DEFAULT 0,
    produto_id         varchar(25)    NOT NULL,
    descricao_produto  varchar(255)   NULL,
    ordem_compra       int8           NOT NULL DEFAULT 0,
    qtde_pedida        numeric(14, 3) NULL,
    filial_id          int4           NULL,
    data_entrega       date           NULL,
    qtde_entregue      numeric(14, 3) NOT NULL DEFAULT 0,
    qtde_pendente      numeric(14, 3) NOT NULL DEFAULT 0,
    preco_compra       numeric(12, 4) NULL DEFAULT 0,
    fornecedor_id      int4           NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item)
);

CREATE TABLE public.entradas_mercadoria (
    data_entrada       date           NULL,
    nro_nfe            varchar(255)   NOT NULL,
    item               int4           NOT NULL DEFAULT 0,
    produto_id         varchar(25)    NOT NULL,
    descricao_produto  varchar(255)   NULL,
    ordem_compra       int8           NOT NULL DEFAULT 0,
    qtde_recebida      numeric(14, 3) NULL,
    filial_id          int4           NULL,
    custo_unitario     numeric(12, 4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

CREATE TABLE public.venda (
    venda_id        int8           NOT NULL,
    data_emissao    date           NOT NULL,
    horariomov      varchar(8)     NOT NULL DEFAULT '00:00:00',
    produto_id      varchar(25)    NOT NULL,
    qtde_vendida    numeric(14, 3) NULL,
    valor_unitario  numeric(12, 4) NOT NULL DEFAULT 0,
    filial_id       int4           NOT NULL DEFAULT 1,
    item            int4           NOT NULL DEFAULT 0,
    unidade_medida  varchar(3)     NULL,
    CONSTRAINT pk_venda PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);
