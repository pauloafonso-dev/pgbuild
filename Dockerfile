FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive

# Instala git e certificados
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clona a branch estável 18 do PostgreSQL (clone raso para acelerar)
RUN mkdir -p /opt/src \
    && git clone --depth 1 --branch REL_18_STABLE https://git.postgresql.org/git/postgresql.git /opt/src/postgres-18

# Diretório de trabalho padrão (o compose monta o host em /workspace)
WORKDIR /workspace

CMD ["/bin/bash"]