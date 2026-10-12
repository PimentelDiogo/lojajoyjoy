#!/usr/bin/env bash
# Prepara build/web para publicar (GitHub Pages ou Vercel).
#
#   tool/web/finalize_build.sh <SITE_URL>   ex.: https://pimenteldiogo.github.io/lojajoyjoy/
#
# - og:url / og:image com URL absoluta (o preview do WhatsApp não aceita relativa);
# - remove source maps (não publicar o código-fonte mapeado).
set -euo pipefail

site_url="${1:?Informe a URL do site (com / no fim)}"
case "$site_url" in
  https://*/) ;;
  *) echo "SITE_URL precisa começar com https:// e terminar com /: $site_url" >&2; exit 1 ;;
esac

dir="${BUILD_DIR:-build/web}"
index="$dir/index.html"
[ -f "$index" ] || { echo "Build não encontrado: $index" >&2; exit 1; }

# `|` como separador: a URL tem barras. Escapa & para o sed.
escaped="${site_url//&/\\&}"
sed -i.bak "s|__SITE_URL__|$escaped|g" "$index" && rm -f "$index.bak"

if grep -q "__SITE_URL__" "$index"; then
  echo "Sobrou __SITE_URL__ em $index" >&2
  exit 1
fi

find "$dir" -name '*.map' -delete
echo "build pronto: og:image = ${site_url}icons/og-image.png"
