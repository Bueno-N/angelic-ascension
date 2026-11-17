#!/usr/bin/env bash
# Garante o layout do repositório: project.godot NA RAIZ e nenhum outro projeto Godot aninhado
# (o Godot ignora subpastas com project.godot e as classes ficam duplicadas/inexistentes).
set -uo pipefail
if [ ! -f project.godot ]; then
  echo "ERRO: project.godot não está na raiz do repositório."
  echo "O conteúdo do zip deve ficar DIRETO na raiz, não dentro de uma subpasta."
  exit 1
fi
others=$(find . -mindepth 2 -name project.godot -not -path './.godot/*' -not -path './.git/*')
if [ -n "$others" ]; then
  echo "ERRO: há outro projeto Godot aninhado (cópia duplicada do jogo):"
  echo "$others"
  echo "Solução: apague essa subpasta duplicada e coloque os arquivos do zip na RAIZ do repositório."
  exit 1
fi
echo "layout OK (um único project.godot, na raiz)"
