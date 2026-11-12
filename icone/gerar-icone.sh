#!/bin/bash
# Refaz o ícone do Expresso: desenha o PNG de 1024 e monta o Expresso.icns na raiz do projeto.
# Só usa o que já vem no Mac: swift, sips e iconutil.
set -euo pipefail
cd "$(dirname "$0")"
swift gerar-icone.swift Expresso-1024.png
SET="$(mktemp -d)/Expresso.iconset"   # pasta temporária, o sistema limpa sozinho
mkdir -p "$SET"
for s in 16 32 128 256 512; do
  sips -z $s $s Expresso-1024.png --out "$SET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d Expresso-1024.png --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o ../Expresso.icns
echo "Pronto: $(cd .. && pwd)/Expresso.icns"
