FROM python:3.12-slim-bookworm

WORKDIR /workspace

# Base tools + Builder's Box requirements (Java 17, Maven, MySQL client)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    ca-certificates \
    nano \
    procps \
    nodejs \
    npm \
    openjdk-17-jdk \
    maven \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Portable JAVA_HOME (works on amd64 and arm64)
RUN JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")" && \
    echo "export JAVA_HOME=${JAVA_HOME_PATH}" > /etc/profile.d/java.sh && \
    echo 'export PATH="${JAVA_HOME}/bin:${PATH}"' >> /etc/profile.d/java.sh && \
    chmod +x /etc/profile.d/java.sh

# Also set for non-login shells
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Jest
RUN npm install jest

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Install OpenCode
RUN npm install -g opencode-ai

# Install ngrok
RUN curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
    | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
    | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update && apt-get install -y ngrok \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh) from the official apt repo (used by the pr-summary agent)
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Claude Code configuration: default settings + status line
# (sources are relative to the build context, i.e. the repo root)
RUN mkdir -p /root/.claude /root/.orca/agent-hooks
COPY .claude/settings.json /root/.claude/settings.json
COPY .orca/agent-hooks/claude-statusline.sh /root/.orca/agent-hooks/claude-statusline.sh
RUN chmod +x /root/.orca/agent-hooks/claude-statusline.sh

# Entrypoint persists Claude Code credentials in the `claude-auth` volume
# while keeping the baked-in settings/hooks in /root/.claude.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Student shell quality-of-life improvements
RUN echo 'export PS1="ai-course:\\w# "' >> /root/.bashrc && \
    echo 'alias ll="ls -alF"' >> /root/.bashrc && \
    echo 'alias la="ls -A"' >> /root/.bashrc && \
    echo 'alias l="ls -CF"' >> /root/.bashrc && \
    echo 'alias python="python3"' >> /root/.bashrc && \
    echo 'alias pip="pip3"' >> /root/.bashrc && \
    echo 'alias mvn="mvn -B"' >> /root/.bashrc && \
    echo '. /etc/profile.d/java.sh' >> /root/.bashrc

# Expose common ports used by Builder's Box
EXPOSE 8080 5173 3306

CMD ["/bin/bash"]
