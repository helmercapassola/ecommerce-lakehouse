# 🚀 GUIA RÁPIDO - Deploy Bundle

## Localização
```
/Workspace/Users/helmercap@gmail.com/ecommerce_dashboards/
```

## Passo 1: Exportar Dashboards (OBRIGATÓRIO)

### Método Python (Recomendado)

Execute este código para exportar os 4 dashboards:

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

import os
os.chdir("/Workspace/Users/helmercap@gmail.com/ecommerce_dashboards")

for name, dash_id in dashboards.items():
    dashboard = w.lakeview.get(dash_id)
    filepath = f"src/dashboards/{name}.lvdash.json"
    with open(filepath, "w") as f:
        f.write(dashboard.serialized_dashboard)
    print(f"✓ Exported: {name}")

print("\n✅ Todos os dashboards exportados!")
```

## Passo 2: Validar (via Web Terminal)

```bash
cd /Workspace/Users/helmercap@gmail.com/ecommerce_dashboards
databricks bundle validate --target dev
```

✅ Deve retornar sem erros

## Passo 3: Deploy Dev

```bash
databricks bundle deploy --target dev
```

Isso vai criar 4 dashboards com prefixo `[DEV]`

## Passo 4: Verificar

```bash
databricks bundle summary --target dev
```

## Passo 5: Deploy Prod (Opcional)

Quando estiver pronto para produção:

```bash
databricks bundle deploy --target prod
```

## ⚙️ Configuração Atual

- **Warehouse**: 0ab33db7097d6231 (Serverless Starter Warehouse)
- **Catalog**: ecommerce
- **Schema**: gold

## 🔍 IDs dos Dashboards Originais

| Dashboard | ID |
|-----------|-----|
| Vendas E-commerce | 01f1b868fd8a1c1fb629aaa308c8e3c0 |
| Diretoria Comercial | 01f1b8ecdc8b142282fc94e9842700a3 |
| Diretoria de Customer Success | 01f1b8ecde4b1ce99a9d1e3c080df996 |
| Diretoria de Pricing | 01f1b8ef948b1974b6f7e6f43a5dd20d |

## ❓ Troubleshooting

### "The zip archive contains no items"
→ Execute o Passo 1 (export) primeiro

### "table not found"
→ Verifique se as tabelas gold existem em `ecommerce.gold`

### "insufficient permissions"
→ Precisa de permissão CREATE dashboard no workspace

---

📚 **Documentação completa**: README.md no bundle root
