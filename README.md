# JOYJOY

Loja web de roupas femininas e masculinas com o pedido finalizado no WhatsApp da Ana.

**Stack:** Flutter Web · Clean Architecture · GetX (estado, DI e rotas) · Supabase.

- Decisões: [`docs/adr/`](docs/adr/README.md)
- Especificação: [`docs/sdd/SDD.md`](docs/sdd/SDD.md)
- Plano do MVP: [`docs/plano/PLANO-EXECUCAO-MVP.md`](docs/plano/PLANO-EXECUCAO-MVP.md)
- Referências visuais: [`docs/design/referencias.md`](docs/design/referencias.md)

## Pré-requisitos

| Ferramenta | Instalação |
|---|---|
| [FVM](https://fvm.app) | Versão do Flutter fixada em `.fvmrc` (**3.44.9**). Rode `fvm install` na raiz |
| Docker Desktop | Necessário para o Supabase local |
| Supabase CLI | `brew install supabase/tap/supabase` |

> Sempre use `fvm flutter ...` neste projeto (a máquina pode ter outra versão global).

## Rodando localmente

```bash
fvm install                          # baixa o Flutter da versão do projeto
fvm flutter pub get

cp env/example.json env/local.json   # env/*.json fica fora do git
fvm flutter run -d chrome --web-port 8080 --dart-define-from-file=env/local.json
```

## Qualidade

```bash
fvm dart format lib test
fvm flutter analyze                  # very_good_analysis
fvm flutter test
fvm flutter build web --release --wasm
```

## Estrutura

```
lib/
├── main.dart          # bootstrap (URL por path, Env)
├── app/               # GetMaterialApp, rotas, bindings, middlewares
├── core/              # config, errors (Result/Failure), usecase, state (UiState), pages
└── features/          # uma pasta por feature: data / domain / presentation
```
