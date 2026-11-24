import argparse
import os
import sys
from datetime import date, datetime, timedelta

import pandas as pd

ARQUIVO = os.environ.get("ARQUIVO_XLSX", "dados/base_teste.xlsx")

ABAS = {
    "fornecedor": ("fornecedor", ["idfornecedor", "razao_social"]),
    "produtos_filial": ("produtos_filial", ["filial_id", "produto_id", "descricao", "estoque",
                                            "preco_unitario", "preco_compra", "preco_venda", "idfornecedor"]),
    "pedido_compra": ("pedido_compra", ["pedido_id", "data_pedido", "item", "produto_id", "descricao_produto",
                                        "ordem_compra", "qtde_pedida", "filial_id", "data_entrega",
                                        "qtde_entregue", "qtde_pendente", "preco_compra", "fornecedor_id"]),
    "entradas_mercadoria": ("entradas_mercadoria", ["data_entrada", "nro_nfe", "item", "produto_id",
                                                    "descricao_produto", "ordem_compra", "qtde_recebida",
                                                    "filial_id", "custo_unitario"]),
    "venda": ("venda", ["venda_id", "data_emissao", "horariomov", "produto_id", "qtde_vendida",
                        "valor_unitario", "filial_id", "item", "unidade_medida"]),
}
RENOMEAR = {"produtos_filial": {"idproduto": "produto_id"}}
COLUNAS_INTEIRAS = {"filial_id", "pedido_id", "item", "ordem_compra", "fornecedor_id", "venda_id"}
COLUNAS_DATA = {"data_pedido", "data_entrega", "data_entrada", "data_emissao"}
COLUNAS_TEXTO = {"idfornecedor", "razao_social", "produto_id", "descricao", "descricao_produto",
                 "nro_nfe", "horariomov", "unidade_medida"}
PADROES = {"horariomov": "00:00:00", "filial_id": None}


def para_data(valor):
    if valor is None or pd.isna(valor):
        return None
    if isinstance(valor, (datetime, pd.Timestamp)):
        return valor.date()
    if isinstance(valor, date):
        return valor
    if isinstance(valor, (int, float)):
        return (datetime(1899, 12, 30) + timedelta(days=float(valor))).date()
    return pd.to_datetime(str(valor).strip(), dayfirst=True).date()


def para_int(valor):
    if valor is None or pd.isna(valor):
        return None
    f = float(valor)
    if f != int(f):
        raise ValueError(f"esperava inteiro, veio {valor}")
    return int(f)


def para_num(valor):
    return None if valor is None or pd.isna(valor) else float(valor)


def para_texto(valor):
    return None if valor is None or pd.isna(valor) else str(valor).strip()


def converter(coluna, valor):
    if coluna in COLUNAS_DATA:
        return para_data(valor)
    if coluna in COLUNAS_INTEIRAS:
        return para_int(valor)
    if coluna in COLUNAS_TEXTO:
        return para_texto(valor)
    return para_num(valor)


def ler_aba(aba):
    df = pd.read_excel(ARQUIVO, sheet_name=aba)
    df.columns = [str(c).strip() for c in df.columns]
    df = df.dropna(how="all")
    return df.rename(columns=RENOMEAR.get(aba, {}))


def avisos_pedido_compra(df):
    extras = [c for c in df.columns if c.startswith("Unnamed") and df[c].notna().any()]
    if extras:
        linhas = df.index[df[extras].notna().any(axis=1)] + 2
        print(f"  AVISO: {len(extras)} colunas além da L têm dados em {len(linhas)} linhas "
              f"(linhas da planilha {linhas.min()}-{linhas.max()}). Elas NÃO são importadas.")
    zero = df[df["ordem_compra"].fillna(0) == 0]
    if len(zero):
        print(f"  AVISO: {len(zero)} pedidos com ordem_compra = 0 (pedido_id {int(zero['pedido_id'].min())} a "
              f"{int(zero['pedido_id'].max())}); não se ligam a nenhuma entrada de mercadoria.")


def linhas_da_aba(aba, df):
    tabela, colunas = ABAS[aba]
    if aba == "pedido_compra":
        df = df.copy()
        df["qtde_pendente"] = df["qtde_pedida"] - df["qtde_entregue"].fillna(0)
    faltando = [c for c in colunas if c not in df.columns]
    if faltando:
        raise SystemExit(f"Aba {aba}: faltam as colunas {faltando}")
    for posicao, (_, linha) in enumerate(df.iterrows()):
        numero_planilha = df.index[posicao] + 2
        try:
            valores = []
            for c in colunas:
                v = converter(c, linha[c])
                if v is None and c in PADROES and PADROES[c] is not None:
                    v = PADROES[c]
                valores.append(v)
            yield numero_planilha, tuple(valores)
        except (ValueError, TypeError) as erro:
            yield numero_planilha, erro


def conectar(sgbd):
    senha = os.environ.get("DB_PASSWORD")
    if not senha:
        raise SystemExit("Defina a variável de ambiente DB_PASSWORD (a senha não fica no código).")
    cfg = dict(host=os.environ.get("DB_HOST", "localhost"), user=os.environ.get("DB_USER"),
               password=senha, database=os.environ.get("DB_NAME", "postgres"))
    if sgbd == "mysql":
        import mysql.connector
        cfg["user"] = cfg["user"] or "root"
        return mysql.connector.connect(port=int(os.environ.get("DB_PORT", 3306)), **cfg)
    import psycopg2
    cfg["user"] = cfg["user"] or "postgres"
    cfg["dbname"] = cfg.pop("database")
    return psycopg2.connect(port=int(os.environ.get("DB_PORT", 5432)), **cfg)


def importar_aba(conn, sgbd, aba):
    tabela, colunas = ABAS[aba]
    df = ler_aba(aba)
    print(f"Importando {aba}: {len(df)} linhas na planilha")
    if aba == "pedido_compra":
        avisos_pedido_compra(df)
    sql = f"INSERT INTO {tabela} ({', '.join(colunas)}) VALUES ({', '.join(['%s'] * len(colunas))})"
    cur = conn.cursor()
    rejeitadas = []
    for numero, dados in linhas_da_aba(aba, df):
        if isinstance(dados, Exception):
            rejeitadas.append((numero, str(dados)))
            continue
        try:
            if sgbd == "postgres":
                cur.execute("SAVEPOINT linha")
            cur.execute(sql, dados)
            if sgbd == "postgres":
                cur.execute("RELEASE SAVEPOINT linha")
        except Exception as erro:
            if sgbd == "postgres":
                cur.execute("ROLLBACK TO SAVEPOINT linha")
            rejeitadas.append((numero, str(erro).strip().splitlines()[0]))
    conn.commit()
    cur.execute(f"SELECT COUNT(*) FROM {tabela}")
    no_banco = cur.fetchone()[0]
    cur.close()
    for numero, motivo in rejeitadas:
        print(f"  REJEITADA linha {numero} da planilha: {motivo}")
    return aba, len(df), no_banco, len(rejeitadas)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sgbd", choices=["postgres", "mysql"], default="postgres")
    sgbd = parser.parse_args().sgbd

    conn = conectar(sgbd)
    print(f"Conectado ao {sgbd}.\n")
    resumo = [importar_aba(conn, sgbd, aba) for aba in ABAS]
    conn.close()

    print("\n" + "=" * 62)
    print(f"{'tabela':<22}{'planilha':>10}{'no banco':>10}{'rejeitadas':>12}")
    ok = True
    for aba, na_planilha, no_banco, rej in resumo:
        bate = na_planilha == no_banco and rej == 0
        marca = "" if bate else "   <-- CONFERIR"
        ok &= bate
        print(f"{aba:<22}{na_planilha:>10}{no_banco:>10}{rej:>12}{marca}")
    print("=" * 62)
    print("Importação conferida." if ok else
          "ATENÇÃO: há linhas rejeitadas ou contagem diferente da planilha (rodou duas vezes sem recriar as tabelas?).")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
