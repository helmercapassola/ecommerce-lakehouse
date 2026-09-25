# =============================================================
# SILVER.CLIENTES
# Limpa e enriquece a tabela de clientes da camada bronze.
#
# REGRAS DE QUALIDADE:
# - Remove duplicatas por id_cliente
# - Guarda o nome original em nome_original (para auditoria)
# - Remove pronomes de tratamento do início do nome (Sr., Sra., Srta.,
#   Dr., Dra.) e aplica formato título (initcap) em nome_cliente
# - estado (UF) em maiúsculas
# - nome_estado e regiao derivados de mapeamento fixo das 27 UFs do IBGE
#   (não existe tabela de estados na bronze)
# - Expectations fail: id_cliente preenchido e regiao preenchida
#   (sem id_cliente não há como identificar o cliente; sem região
#   não é possível análise geográfica)
# =============================================================

from pyspark import pipelines as dp
from pyspark.sql import functions as F

# Mapeamento fixo das 27 UFs do IBGE: UF -> (nome_estado, regiao)
ESTADOS_IBGE = {
    "AC": ("Acre", "Norte"),
    "AL": ("Alagoas", "Nordeste"),
    "AP": ("Amapá", "Norte"),
    "AM": ("Amazonas", "Norte"),
    "BA": ("Bahia", "Nordeste"),
    "CE": ("Ceará", "Nordeste"),
    "DF": ("Distrito Federal", "Centro-Oeste"),
    "ES": ("Espírito Santo", "Sudeste"),
    "GO": ("Goiás", "Centro-Oeste"),
    "MA": ("Maranhão", "Nordeste"),
    "MT": ("Mato Grosso", "Centro-Oeste"),
    "MS": ("Mato Grosso do Sul", "Centro-Oeste"),
    "MG": ("Minas Gerais", "Sudeste"),
    "PA": ("Pará", "Norte"),
    "PB": ("Paraíba", "Nordeste"),
    "PR": ("Paraná", "Sul"),
    "PE": ("Pernambuco", "Nordeste"),
    "PI": ("Piauí", "Nordeste"),
    "RJ": ("Rio de Janeiro", "Sudeste"),
    "RN": ("Rio Grande do Norte", "Nordeste"),
    "RS": ("Rio Grande do Sul", "Sul"),
    "RO": ("Rondônia", "Norte"),
    "RR": ("Roraima", "Norte"),
    "SC": ("Santa Catarina", "Sul"),
    "SP": ("São Paulo", "Sudeste"),
    "SE": ("Sergipe", "Nordeste"),
    "TO": ("Tocantins", "Norte"),
}


@dp.materialized_view()
@dp.expect_all_or_fail({
    "id_cliente_preenchido": "id_cliente IS NOT NULL",
    "regiao_preenchida": "regiao IS NOT NULL",
})
def clientes():
    df = spark.read.table("bronze.clientes")

    # Remove duplicatas por id_cliente
    df = df.dropDuplicates(["id_cliente"])

    # Guarda o nome original para auditoria
    df = df.withColumn("nome_original", F.col("nome_cliente"))

    # Remove pronomes de tratamento do início e aplica formato título
    # Padrões removidos: "Sr. ", "Sra. ", "Srta. ", "Dr. ", "Dra. "
    df = df.withColumn(
        "nome_cliente",
        F.initcap(
            F.regexp_replace(
                F.col("nome_cliente"),
                r"^(Sr\.|Sra\.|Srta\.|Dr\.|Dra\.)\s+",
                "",
            )
        ),
    )

    # estado (UF) em maiúsculas
    df = df.withColumn("estado", F.upper(F.col("estado")))

    # nome_estado e regiao a partir do mapeamento IBGE
    estados_df = spark.createDataFrame(
        [(uf, nome, regiao) for uf, (nome, regiao) in ESTADOS_IBGE.items()],
        ["estado_uf", "nome_estado", "regiao"],
    )
    df = df.join(
        estados_df, df.estado == estados_df.estado_uf, "left"
    ).drop("estado_uf")

    # Seleciona as colunas finais
    df = df.select(
        "id_cliente",
        "nome_original",
        "nome_cliente",
        "estado",
        "nome_estado",
        "regiao",
        "pais",
        "data_cadastro",
    )

    return df