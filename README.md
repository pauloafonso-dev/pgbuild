# pgbuild — Build e ambiente para compilar PostgreSQL

Resumo
- Imagem Debian com dependências para compilar PostgreSQL, zsh + Oh My Zsh, powerlevel10k e plugins.
- Persistência:
  - Binários compilados: bind mount ./pgsql -> /usr/local/pgsql
  - Dados do Postgres: volume nomeado `pgdata` -> /var/lib/postgresql/data
  - Configs do shell: bind mount ./dotfiles -> /workspace/dotfiles (symlinks são criados para /root)

Pré-requisitos
- Docker e Docker Compose (v2).
- No host: configure o terminal para usar uma Nerd Font (Meslo) para ver ícones do Powerlevel10k.

Comandos úteis
- Build e start (rebuild quando alterar Dockerfile/entrypoint):
  - docker compose up -d --build
- Start sem rebuild:
  - docker compose up -d
- Parar e remover containers (preserva volumes nomeados):
  - docker compose down
- Parar e remover containers + volumes nomeados:
  - docker compose down -v
- Entrar no shell zsh do container:
  - docker compose exec pg-build zsh -l
- Logs:
  - docker compose logs -f pg-build
- Executar entrypoint manualmente (debug):
  - docker compose exec pg-build /usr/local/bin/entrypoint.sh /usr/bin/true

Como funciona a persistência de dotfiles (zsh / p10k)
- O entrypoint popula ./dotfiles na primeira execução com defaults embutidos na imagem.
- O entrypoint cria symlinks em /root apontando para /workspace/dotfiles, assim alterações (ex.: `p10k configure`) são gravadas no host e persistem entre recriações do container.
- Evite montar arquivos individuais (./dotfiles/.zshrc:/root/.zshrc) — o compose já está configurado para montar o diretório inteiro.

Dicas de depuração
- Se o entrypoint não copiar, faça:
  - docker compose up -d --build
  - docker compose logs --tail=200 pg-build
  - docker compose exec pg-build bash -lc "ls -la /workspace/dotfiles; ls -la /root; readlink -f /root/.zshrc || true"
- Permissões: se o container não conseguir gravar em ./dotfiles, ajuste dono do host:
  - sudo chown -R 0:0 ./dotfiles
  - ou permita gravação para seu usuário conforme preferir.

Observações
- Fontes instaladas dentro do container não mudam a fonte do terminal host. Configure a fonte do seu terminal para MesloLGS NF / outra Nerd Font.
- Binários compilados dentro do container funcionarão se você usar containers baseados em mesma arquitetura e libc. Se trocar a imagem base, pode haver incompatibilidades.

Arquivos importantes
- Dockerfile — imagem base e instalação de dependências
- docker-compose.yml — volumes, mounts e serviço
- scripts/entrypoint.sh — lógica de população de dotfiles e criação de symlinks
- .gitignore — evita versionar dotfiles e pgsql bind

Licença
- Uso pessoal / didático.
