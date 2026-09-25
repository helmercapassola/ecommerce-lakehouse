# Databricks notebook source
# =============================================================
# INGESTAO BRONZE - Le ficheiros Parquet do S3 e escreve tabelas Delta
# =============================================================
# Credenciais via variaveis de ambiente (NUNCA hardcoded).
# Ver .env.example para configuracao.
#
# No Databricks, prefira Databricks Secrets:
#   dbutils.secrets.get(scope="aws", key="access_key_id")
#   dbutils.secrets.get(scope="aws", key="secret_access_key")
# =============================================================

import os
import io
import boto3
import pandas as pd

# --- Configuracao via variaveis de ambiente ---
aws_access_key_id = os.environ.get("AWS_ACCESS_KEY_ID")
aws_secret_access_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
aws_region = os.environ.get("AWS_REGION", "eu-central-1")
s3_endpoint = os.environ.get("S3_ENDPOINT_URL")
bucket_name = os.environ.get("S3_BUCKET", "DataLakeEcommerce")

# Alternativa: Databricks Secrets
# aws_access_key_id = dbutils.secrets.get(scope="aws", key="access_key_id")
# aws_secret_access_key = dbutils.secrets.get(scope="aws", key="secret_access_key")

if not aws_access_key_id or not aws_secret_access_key:
    raise ValueError(
        "Credenciais AWS nao configuradas. "
        "Defina AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY nas variaveis de ambiente "
        "ou use Databricks Secrets."
    )

# --- Cliente S3 ---
s3 = boto3.client(
    "s3",
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=aws_region,
    endpoint_url=s3_endpoint,
)

# --- Teste de acesso ---
response = s3.list_buckets()
print("Buckets disponiveis:")
for b in response["Buckets"]:
    print(f"  {b['Name']}")

# --- Ficheiros Parquet a ingerir e tabelas Bronze correspondentes ---
files = {
    "clientes.parquet": "ecommerce.bronze.clientes",
    "vendas.parquet": "ecommerce.bronze.vendas",
    "produtos.parquet": "ecommerce.bronze.produtos",
    "preco_competidores.parquet": "ecommerce.bronze.preco_competidores",
}

# --- Ingestao ---
for key, table_name in files.items():
    response = s3.get_object(Bucket=bucket_name, Key=key)
    df = pd.read_parquet(io.BytesIO(response["Body"].read()))
    spark_df = spark.createDataFrame(df)
    spark_df.write.format("delta").mode("overwrite").saveAsTable(table_name)
    count = spark_df.count()
    print(f"OK {key} -> {table_name} ({count} registros)")

print("\nIngestao Bronze concluida!")
