# Dados

## Origem

Os dados deste projeto sao ficheiros Parquet armazenados num bucket S3 compativel (Supabase S3-compatible Storage). O bucket chama-se `DataLakeEcommerce` e contem 4 ficheiros:

| Ficheiro | Descricao | Colunas |
| --- | --- | --- |
| clientes.parquet | Cadastro de clientes | id_cliente, nome_cliente, estado, pais, data_cadastro |
| vendas.parquet | Transacoes de vendas | id_venda, data_venda, id_cliente, id_produto, canal_venda, quantidade, preco_unitario |
| produtos.parquet | Catalogo de produtos | id_produto, nome_produto, categoria, marca, preco_atual, data_criacao |
| preco_competidores.parquet | Precos de concorrentes | id_produto, nome_concorrente, preco_concorrente, data_coleta |

## Periodo dos Dados

Os dados cobrem o periodo de **13/12/2025 a 11/01/2026** (aproximadamente 30 dias de vendas).

## Volume

| Dataset | Registros |
| --- | --- |
| clientes | 50 |
| vendas | 3.020 |
| produtos | ~215 |
| preco_competidores | ~860 |

## Formato

* **Armazenamento**: Parquet (formato colunar)
* **Bucket S3**: DataLakeEcommerce
* **Regiao**: eu-central-1

## Como Obter Dados Equivalentes

Os ficheiros Parquet nao sao publicados neste repositorio por seguraca. Para reproduzir o projeto:

1. **Gerar dados sinteticos**: Criar ficheiros Parquet com esquema compativel usando Python:
   ```python
   import pandas as pd
   # clientes
   pd.DataFrame({
       "id_cliente": ["cus_001", "cus_002"],
       "nome_cliente": ["Sr. Joao Silva", "Ana Souza"],
       "estado": ["SP", "MG"],
       "pais": ["Brasil", "Brasil"],
       "data_cadastro": ["2023-01-15", "2024-03-20"]
   }).to_parquet("clientes.parquet")
   ```

2. **Upload para S3**: Subir os ficheiros para um bucket S3 compativel.

3. **Configurar variaveis de ambiente**: Ver `.env.example`.

4. **Executar ingestao**: Rodar o notebook `notebooks/ingestion/extratload.py`.

## Esquema Esperado

### clientes.parquet
| Coluna | Tipo |
| --- | --- |
| id_cliente | string |
| nome_cliente | string |
| estado | string (UF, ex: SP, MG) |
| pais | string |
| data_cadastro | timestamp |

### vendas.parquet
| Coluna | Tipo |
| --- | --- |
| id_venda | string |
| data_venda | timestamp |
| id_cliente | string |
| id_produto | string |
| canal_venda | string (ecommerce ou loja_fisica) |
| quantidade | long |
| preco_unitario | double |

### produtos.parquet
| Coluna | Tipo |
| --- | --- |
| id_produto | string |
| nome_produto | string |
| categoria | string |
| marca | string |
| preco_atual | double |
| data_criacao | timestamp |

### preco_competidores.parquet
| Coluna | Tipo |
| --- | --- |
| id_produto | string |
| nome_concorrente | string (Mercado Livre, Amazon, Magalu, Shopee) |
| preco_concorrente | double |
| data_coleta | string (timestamp) |
