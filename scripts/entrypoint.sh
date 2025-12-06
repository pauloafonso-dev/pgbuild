#!/usr/bin/env bash
set -uo pipefail

BASE_DOTDIR=/workspace/dotfiles
ALUNO_DOTDIR="$BASE_DOTDIR/aluno"
ROOT_DOTDIR="$BASE_DOTDIR/root"
DEFAULT=/usr/local/share/dotfiles-defaults

mkdir -p "$ALUNO_DOTDIR" "$ROOT_DOTDIR"

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

###########################
# dotfiles do ALUNO
###########################
if [ -d "$DEFAULT" ]; then
  # defaults foram gerados a partir da home do aluno no Dockerfile
  copy_file "$DEFAULT/.zshrc"    "$ALUNO_DOTDIR/.zshrc"
  copy_file "$DEFAULT/.p10k.zsh" "$ALUNO_DOTDIR/.p10k.zsh"
  copy_dir  "$DEFAULT/oh-my-zsh" "$ALUNO_DOTDIR/oh-my-zsh"
fi

# garante arquivo p10k para o aluno
if [ ! -f "$ALUNO_DOTDIR/.p10k.zsh" ]; then
  : > "$ALUNO_DOTDIR/.p10k.zsh"
  echo "created empty $ALUNO_DOTDIR/.p10k.zsh"
fi

# symlinks na home do aluno
ln -sf "$ALUNO_DOTDIR/.zshrc"    /home/aluno/.zshrc  2>/dev/null || true
ln -sf "$ALUNO_DOTDIR/.p10k.zsh" /home/aluno/.p10k.zsh 2>/dev/null || true
if [ -d "$ALUNO_DOTDIR/oh-my-zsh" ]; then
  rm -rf /home/aluno/.oh-my-zsh 2>/dev/null || true
  ln -s "$ALUNO_DOTDIR/oh-my-zsh" /home/aluno/.oh-my-zsh 2>/dev/null || true
fi

###########################
# dotfiles do ROOT (opcional)
###########################
# Se você quiser que root também persista as configs pelo volume:
copy_file "$DEFAULT/.zshrc"    "$ROOT_DOTDIR/.zshrc"
copy_file "$DEFAULT/.p10k.zsh" "$ROOT_DOTDIR/.p10k.zsh"
copy_dir  "$DEFAULT/oh-my-zsh" "$ROOT_DOTDIR/oh-my-zsh"

if [ ! -f "$ROOT_DOTDIR/.p10k.zsh" ]; then
  : > "$ROOT_DOTDIR/.p10k.zsh"
  echo "created empty $ROOT_DOTDIR/.p10k.zsh"
fi

ln -sf "$ROOT_DOTDIR/.zshrc"    /root/.zshrc     2>/dev/null || true
ln -sf "$ROOT_DOTDIR/.p10k.zsh" /root/.p10k.zsh  2>/dev/null || true
if [ -d "$ROOT_DOTDIR/oh-my-zsh" ]; then
  rm -rf /root/.oh-my-zsh 2>/dev/null || true
  ln -s "$ROOT_DOTDIR/oh-my-zsh" /root/.oh-my-zsh 2>/dev/null || true
fi

# permissões (não falha se não puder)
chown -R aluno:aluno "$ALUNO_DOTDIR" 2>/dev/null || true
chown -R root:root   "$ROOT_DOTDIR"  2>/dev/null || true

###########################
# start automático Postgres
###########################
export PATH="/usr/local/pgsql/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/local/pgsql/lib:${LD_LIBRARY_PATH:-}"

# garante owner do data dir (caso volume nomeado sobrescreva)
chown -R postgres:postgres /var/lib/postgresql 2>/dev/null || true

# inicia servidor como usuário postgres e espera ficar pronto
if ! su - postgres -c '/usr/local/pgsql/bin/pg_ctl -w -D /var/lib/postgresql/data -l /var/lib/postgresql/data/logfile start'; then
  echo "PostgreSQL failed to start (pg_ctl returned non-zero code)" >&2
  if [ -f /var/lib/postgresql/data/logfile ]; then
    echo "===== PostgreSQL logfile =====" >&2
    cat /var/lib/postgresql/data/logfile >&2
    echo "===== end logfile =====" >&2
  fi
  # NÃO dá exit 1 aqui; apenas entra no shell para permitir debug
fi

# entra no shell como aluno (servidor pode ter iniciado ou não)
if [ "$#" -eq 0 ]; then
  exec su - aluno -c "/usr/bin/zsh -l"
else
  exec su - aluno -c "$*"
fi