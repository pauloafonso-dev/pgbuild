FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/usr/bin/zsh
ENV PATH="/usr/local/pgsql/bin:${PATH}"
ENV LD_LIBRARY_PATH=/usr/local/pgsql/lib

# Instala git, certificados e dependências para build do PostgreSQL, zsh e fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc make bison flex pkg-config perl python3 \
    libreadline-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev libicu-dev \
    ca-certificates git wget curl sudo zsh locales fontconfig procps htop \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen C.UTF-8

# criar usuários: postgres (para o servidor) e aluno (para uso interativo)
RUN useradd -m -s /bin/bash postgres && \
    useradd -m -s /bin/bash aluno && \
    echo "aluno:rnpesr" | chpasswd && \
    mkdir -p /opt/src /workspace /var/lib/postgresql/data && \
    chown -R postgres:postgres /opt/src /var/lib/postgresql && \
    chown -R aluno:aluno /workspace && \
    echo "aluno ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/aluno && \
    chmod 440 /etc/sudoers.d/aluno && \
    echo "postgres:postgres" | chpasswd

# Clona a versão 15.2 do PostgreSQL (tag REL_15_2) com ajustes para reduzir erros de rede
RUN git config --global http.version HTTP/1.1 && \
    git config --global http.postBuffer 524288000 && \
    git clone --depth 1 --single-branch --branch REL_15_2 \
    https://git.postgresql.org/git/postgresql.git /opt/src/postgres-15 && \
    chown -R postgres:postgres /opt/src/postgres-15

############################
# Build e instalação PG 15.2
############################
USER postgres
WORKDIR /opt/src/postgres-15

# configure + make
RUN ./configure --prefix=/usr/local/pgsql --enable-shared && \
    make -j"$(nproc)"

# instalar como root
USER root
RUN make -C /opt/src/postgres-15 install

############################################
# Inicializa cluster com superuser "postgres"
############################################
USER postgres
RUN /usr/local/pgsql/bin/initdb \
    -D /var/lib/postgresql/data \
    --username=postgres \
    --auth=trust \
    --no-sync

#########################
# Configuração de shell
#########################
# Agora configuramos oh-my-zsh direto para o usuário 'aluno'
USER aluno
WORKDIR /home/aluno

RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /home/aluno/.oh-my-zsh \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/aluno/.oh-my-zsh/custom/themes/powerlevel10k \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /home/aluno/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /home/aluno/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts \
    && /tmp/nerd-fonts/install.sh Meslo \
    && fc-cache -fv || true \
    && rm -rf /tmp/nerd-fonts

RUN cp /home/aluno/.oh-my-zsh/templates/zshrc.zsh-template /home/aluno/.zshrc \
    && sed -i 's|^ZSH=.*|ZSH="/home/aluno/.oh-my-zsh"|' /home/aluno/.zshrc \
    && sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /home/aluno/.zshrc \
    && sed -i 's|^plugins=.*|plugins=(git)|' /home/aluno/.zshrc \
    && printf '\n# Plugins (sourced after oh-my-zsh)\nsource $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh\nsource $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n' >> /home/aluno/.zshrc \
    && printf '\n# Add PostgreSQL bin to PATH\nexport PATH="/usr/local/pgsql/bin:$PATH"\nexport LD_LIBRARY_PATH="/usr/local/pgsql/lib:$LD_LIBRARY_PATH"\n' >> /home/aluno/.zshrc

# garantir permissões da home do aluno (caso algo tenha sido criado como root)
USER root
RUN chown -R aluno:aluno /home/aluno

# salva versões padrão dos dotfiles em local não montado (para uso pelo entrypoint)
RUN mkdir -p /usr/local/share/dotfiles-defaults \
    && cp -a /home/aluno/.zshrc /usr/local/share/dotfiles-defaults/.zshrc \
    && cp -a /home/aluno/.p10k.zsh /usr/local/share/dotfiles-defaults/.p10k.zsh || true \
    && cp -a /home/aluno/.oh-my-zsh /usr/local/share/dotfiles-defaults/oh-my-zsh

# copia entrypoint e dá permissão
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# trabalho de desenvolvimento acontece em /workspace
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# última etapa: abrir shell como usuário 'aluno'
CMD ["/usr/bin/zsh", "-l"]