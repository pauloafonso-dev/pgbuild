FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/usr/bin/zsh
ENV PATH="/usr/local/pgsql/bin:${PATH}"

# Instala git, certificados e dependências para build do PostgreSQL, zsh e fonts
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git ca-certificates make gcc g++ tar \
    libreadline-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev \
    zsh wget curl fontconfig unzip pkg-config libicu-dev \
    bison flex libperl-dev python3 python3-dev tcl-dev \
    libpam0g-dev libkrb5-dev libldap2-dev libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Clona a branch estável 18 do PostgreSQL (clone raso para acelerar)
RUN mkdir -p /opt/src \
    && git clone --depth 1 --branch REL_18_STABLE https://git.postgresql.org/git/postgresql.git /opt/src/postgres-18

# Instala oh-my-zsh, powerlevel10k, plugins e Meslo Nerd Font
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /root/.oh-my-zsh \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts \
    && /tmp/nerd-fonts/install.sh Meslo \
    && fc-cache -fv || true \
    && rm -rf /tmp/nerd-fonts

# Configura .zshrc para usar powerlevel10k e plugins
RUN cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc \
    && sed -i 's|^ZSH=.*|ZSH="/root/.oh-my-zsh"|' /root/.zshrc \
    && sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' /root/.zshrc \
    && sed -i 's|^plugins=.*|plugins=(git)|' /root/.zshrc \
    && printf '\n# Plugins (sourced after oh-my-zsh)\nsource $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh\nsource $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n' >> /root/.zshrc \
    && printf '\n# Add PostgreSQL bin to PATH\nexport PATH="/usr/local/pgsql/bin:$PATH"\n' >> /root/.zshrc

# salva versões padrão dos dotfiles em local não montado (para uso pelo entrypoint)
RUN mkdir -p /usr/local/share/dotfiles-defaults \
    && cp -a /root/.zshrc /usr/local/share/dotfiles-defaults/.zshrc \
    && cp -a /root/.p10k.zsh /usr/local/share/dotfiles-defaults/.p10k.zsh || true \
    && cp -a /root/.oh-my-zsh /usr/local/share/dotfiles-defaults/oh-my-zsh

# copia entrypoint e dá permissão
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]