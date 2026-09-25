# E-commerce Dashboards Bundle

Bundle Declarativo de Automação (DAB) para deploy dos 4 dashboards do projeto e-commerce.

## 📊 Dashboards Incluídos

1. **Vendas E-commerce - Visão Executiva** (ID: 01f1b868fd8a1c1fb629aaa308c8e3c0)
   - KPIs: Receita Total, Total de Vendas, Ticket Médio, Vendas E-commerce
   - Análises: Por canal, produto, cliente, categoria, hora do dia
   - 3 páginas canvas + filtros globais

2. **Diretoria Comercial** (ID: 01f1b8ecdc8b142282fc94e9842700a3)
   - KPIs: Produtos Cadastrados, Categorias, Receita Total, Itens Vendidos
   - Análises: Top produtos, receita por categoria/marca, itens por categoria
   - Filtros globais: categoria, marca

3. **Diretoria de Customer Success** (ID: 01f1b8ecde4b1ce99a9d1e3c080df996)
   - KPIs: Total Clientes, Clientes VIP, % Receita VIP, Ticket Médio VIP
   - Análises: Receita por região, clientes por segmento, ranking VIP
   - Filtros globais: segmento, região

4. **Diretoria de Pricing** (ID: 01f1b8ef948b1974b6f7e6f43a5dd20d)
   - KPIs: Produtos Monitorados, Mais Caros Confirmados, Receita Total, Preços Suspeitos
   - Análises: Classificação de preços, diferença vs média/concorrentes, ranking
   - Filtros globais: categoria, classificação

## 📁 Estrutura do Bundle

```
ecommerce_dashboards/
├── databricks.yml              # Configuração principal do bundle
└── src/
    └── dashboards/
        ├── vendas_ecommerce.lvdash.json
        ├── diretoria_comercial.lvdash.json
        ├── diretoria_customer_success.lvdash.json
        └── diretoria_pricing.lvdash.json
```

## ⚙️ Configuração

### Variáveis (databricks.yml)

- `warehouse_id`: **0ab33db7097d6231** (Serverless Starter Warehouse)
- `catalog_name`: **ecommerce**
- `schema_name`: **gold**

### Targets

- **dev** (padrão): mode=development
- **prod**: mode=production

## 🚀 Como Fazer Deploy

### Pré-requisitos

1. Databricks CLI configurado e autenticado
2. Permissões para criar dashboards no workspace
3. Acesso ao catálogo `ecommerce` e schema `gold`

### Passos para Deploy

#### 1. Exportar Dashboards Completos (⚠️ PENDENTE)

Os arquivos `.lvdash.json` atualmente são placeholders. Você precisa exportar o JSON completo de cada dashboard:

**Opção A: Via Python SDK**

```python
from databricks.sdk import WorkspaceClient
import json

w = WorkspaceClient()

dashboards = {
    "vendas_ecommerce": "01f1b868fd8a1c1fb629aaa308c8e3c0",
    "diretoria_comercial": "01f1b8ecdc8b142282fc94e9842700a3",
    "diretoria_customer_success": "01f1b8ecde4b1ce99a9d1e3c080df996",
    "diretoria_pricing": "01f1b8ef948b1974b6f7e6f43a5dd20d"
}

for name, dash_id in dashboards.items():
    dashboard = w.lakeview.get(dash_id)
    with open(f"src/dashboards/{name}.lvdash.json", "w") as f:
        f.write(dashboard.serialized_dashboard)
    print(f"Exported {name}")
```

**Opção B: Via UI**

1. Abra cada dashboard
2. Export → Download JSON
3. Salve em `src/dashboards/{nome}.lvdash.json`

#### 2. Validar Bundle

No **web terminal** do Databricks:

```bash
cd /Workspace/Users/helmercap@gmail.com/ecommerce_dashboards
databricks bundle validate --target dev
```

Deve retornar sem erros.

#### 3. Deploy para Dev

```bash
databricks bundle deploy --target dev
```

Isso vai:
- Criar cópias dos 4 dashboards com prefixo `[DEV]`
- Configurar warehouse_id automaticamente
- Publicar em modo desenvolvimento

#### 4. Verificar Deploy

```bash
databricks bundle summary --target dev
```

Liste os dashboards criados e verifique os IDs.

#### 5. Deploy para Produção (Opcional)

Quando estiver pronto:

```bash
databricks bundle deploy --target prod
```

## 📝 Notas Importantes

1. **Dashboard Export**: Os arquivos `.lvdash.json` atuais são placeholders. Execute o Passo 1 antes do deploy.

2. **IDs dos Dashboards**: Os IDs originais estão documentados nos placeholders para referência.

3. **Warehouse ID**: Já configurado automaticamente. Se precisar mudar, edite a variável `warehouse_id` em `databricks.yml`.

4. **Catálogo e Schema**: Todos os dashboards usam `ecommerce.gold`. Certifique-se de que as tabelas existem:
   - `ecommerce.gold.vendas_diarias`
   - `ecommerce.gold.vendas_por_produto`
   - `ecommerce.gold.vendas_por_cliente`
   - `ecommerce.gold.clientes_segmentacao`
   - `ecommerce.gold.precos_competitividade`

5. **Modo Development**: Dashboards em dev têm prefixo `[DEV]` e permitem edição mais livre.

## 🔧 Troubleshooting

### Erro: "dashboard not found"

Verifique se os arquivos `.lvdash.json` foram exportados corretamente (Passo 1).

### Erro: "table not found"

Confirme que todas as tabelas gold existem no catálogo `ecommerce` schema `gold`.

### Erro: "insufficient permissions"

Verifique permissões:
- CREATE dashboard no workspace
- USE CATALOG ecommerce
- USE SCHEMA ecommerce.gold
- SELECT nas tabelas gold

## 📚 Referências

- [Databricks Asset Bundles](https://docs.databricks.com/dev-tools/bundles/index.html)
- [Dashboard Deployment](https://docs.databricks.com/dashboards/lakeview.html)
- Bundle root: `/Workspace/Users/helmercap@gmail.com/ecommerce_dashboards`

---

**Status**: ✅ Estrutura criada | ⏳ Export pendente | ⏳ Deploy pendente
**Criado**: 2026-09-25
**Warehouse**: 0ab33db7097d6231 (Serverless Starter Warehouse)
