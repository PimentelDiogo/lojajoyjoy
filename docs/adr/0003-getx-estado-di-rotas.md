# ADR-0003 — GetX para estado, injeção de dependência e rotas

- **Status:** Aceito
- **Data:** 2026-10-02

## Contexto

Precisamos de gerência de estado (carrinho, catálogo, tema, sessão admin), injeção de
dependência (repositórios, serviços Supabase) e roteamento com URLs reais para web
(`/pedido/:code`). Preferência explícita do Diogo: **GetX**.

## Decisão

Usar **GetX** (`get`) para os três papéis, com regras para não "espalhar" o framework:

| Papel | Como |
|---|---|
| **Estado** | `GetxController` + `Rx`/`.obs` + `Obx`. Um controller por tela/feature. |
| **DI** | `Bindings` por rota (`Get.lazyPut`) + `InitialBinding` para serviços globais (`Get.put(..., permanent: true)`). |
| **Rotas** | `GetMaterialApp` + `getPages` com rotas nomeadas e parâmetros (`/produto/:slug`, `/pedido/:code`). |
| **Guards** | `GetMiddleware` para proteger `/admin/**` (redireciona para `/admin/login`). |
| **Persistência leve** | `get_storage` (localStorage no web) para carrinho, tema e `session_id`. |

### Regras de uso (boas práticas)

1. **GetX só na camada `presentation` e em `bindings`** (Clean Architecture, ADR-0004).
   `domain` é Dart puro; `data` não conhece GetX. Use cases, repositórios e datasources recebem
   dependências **pelo construtor** — o `Binding` é quem resolve com `Get.find()` (testáveis sem GetX).
   Fluxo: `View → Controller → UseCase → Repository (contrato) ← RepositoryImpl → DataSource`.
2. **Nada de `Get.find()` dentro de widgets de `core/widgets`** — componentes compartilhados
   recebem dados por parâmetro.
3. **Evitar `Get.context`/`Get.snackbar` em controllers** — expor estado (`Rx<UiState>`) e
   deixar a View reagir. Mantém controllers testáveis.
4. Controllers testados com `Get.testMode = true` e repositórios mockados (`mocktail`).

## Alternativas consideradas

| Alternativa | Trade-off |
|---|---|
| Riverpod + go_router | Mais "moderno", compile-safe; curva maior e não é a preferência do time. |
| Bloc/Cubit | Muito testável e explícito, porém verboso para um projeto pequeno. |

## Consequências

- **+** Produtividade alta, pouco boilerplate, DI e rotas no mesmo pacote.
- **−** GetX tem histórico de manutenção irregular e é "mágico" (service locator global).
  Mitigação: as regras acima isolam o GetX; trocar no futuro afeta só `presentation`/`bindings`.
- **−** Atenção a deep link no web: testar refresh direto em `/pedido/XXXX` (precisa do rewrite SPA, ADR-0012).
