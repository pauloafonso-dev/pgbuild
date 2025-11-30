#!/usr/bin/env bash
set -euo pipefail

DOTDIR=/workspace/dotfiles
DEFAULT=/usr/local/share/dotfiles-defaults

mkdir -p "$DOTDIR"

copy_file() {
  local src="$1" dest="$2"
  if [ -f "$src" ] && { [ ! -e "$dest" ] || [ ! -s "$dest" ]; }; then
    cp -a "$src" "$dest"
    echo "copied $src -> $dest"
  fi
}

copy_dir() {
  local src="$1" dest="$2"
  if [ -d "$src" ] && { [ ! -d "$dest" ] || [ -z "$(ls -A "$dest" 2>/dev/null)" ]; }; then
    rm -rf "$dest" || true
    cp -a "$src" "$dest"
    echo "copied dir $src -> $dest"
  fi
}

# copia defaults se existirem
if [ -d "$DEFAULT" ]; then
  copy_file "$DEFAULT/.zshrc" "$DOTDIR/.zshrc"
  copy_file "$DEFAULT/.p10k.zsh" "$DOTDIR/.p10k.zsh"
  copy_dir  "$DEFAULT/oh-my-zsh" "$DOTDIR/oh-my-zsh"
fi

# garante que exista um arquivo p10k para que o wizard grave no bind (se ainda não existe)
if [ ! -f "$DOTDIR/.p10k.zsh" ]; then
  : > "$DOTDIR/.p10k.zsh"
  echo "created empty $DOTDIR/.p10k.zsh"
fi

# garante permissões (não falha se não puder)
chown -R root:root "$DOTDIR" 2>/dev/null || true

# cria/atualiza symlinks em /root apontando para o diretório bindado
ln -sf "$DOTDIR/.zshrc" /root/.zshrc 2>/dev/null || true
ln -sf "$DOTDIR/.p10k.zsh" /root/.p10k.zsh 2>/dev/null || true

if [ -d "$DOTDIR/oh-my-zsh" ]; then
  rm -rf /root/.oh-my-zsh 2>/dev/null || true
  ln -s "$DOTDIR/oh-my-zsh" /root/.oh-my-zsh 2>/dev/null || true
fi

exec "$@"