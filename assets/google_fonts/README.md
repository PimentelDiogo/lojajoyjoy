# Fontes embutidas

Usadas pelo `google_fonts` com `allowRuntimeFetching = false` (ver `lib/core/theme/app_typography.dart`).
Nada é baixado do Google em tempo de execução.

| Arquivo | Origem |
|---|---|
| `Inter-{Regular,Medium,SemiBold,Bold}.ttf` | TTF estático do próprio `google_fonts` (fonts.gstatic.com/s/a/<hash>.ttf) |
| `Poppins-{Regular,Medium,SemiBold,Bold}.ttf` | idem |
| `CormorantGaramond-SemiBold.ttf` | idem (só no wordmark JOYJOY) |

Cortadas para o alfabeto latino (português + pontuação) com `pyftsubset`:

```bash
pyftsubset Fonte.ttf --layout-features='*' --output-file=assets/google_fonts/Fonte.ttf \
  --unicodes="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212,U+2215,U+FEFF,U+FFFD"
```

O nome do arquivo precisa seguir o padrão do `google_fonts` (`Familia-Peso.ttf`). Peso novo no app →
adicionar o arquivo aqui e em `AppTypography.bundledWeights` (o teste `app_typography_test.dart` confere).

Licença: SIL Open Font License 1.1 (`OFL-*.txt`, exibidas na tela de licenças).
