# Builders-Box — Container Setup & Security Notes

## Build

```bash
docker build --pull --rm -f Dockerfile -t builders-box .
```

## Run

Baseline (persistent Claude credentials in the `claude-auth` volume):

```bash
docker run -it --rm \
  -v "${PWD}:/workspace" \
  -v "claude-auth:/claude-auth" \
  -w /workspace \
  builders-box
```

Full dev run (reuse host Claude auth, pass the GitHub token from `.env`,
and register the repo's Claude specialist agents globally inside the container):

One-shot (handles port conflicts automatically):

```bash
./run.sh
```

Equivalent manual command (ensure no trailing spaces after `\`):

```bash
GH_TOKEN="$(sed -n 's/^GH_TOKEN=//p' .env)" docker run -it --rm \
  -v "${PWD}:/workspace" \
  -v "${HOME}/.claude/.credentials.json:/root/.claude/.credentials.json" \
  -v "${PWD}/.claude/agents:/root/.claude/agents" \
  -e GH_TOKEN \
  -w /workspace \
  -p 8080:8080 -p 5173:5173 \
  builders-box
```

- **Mounted path**: only `~/EDU/HireHuman/Builders-Box` → `/workspace`
- **Claude auth**: the host's `~/.claude/.credentials.json` is bind-mounted (read/write, so token refreshes land on the host). The entrypoint detects the bind mount and leaves it in place.
- **GitHub token**: `GH_TOKEN` is taken from `.env` and exposed to `gh`/git inside the container. No other `.env` values are passed.
- **Claude agents**: `.claude/agents/*.md` are bind-mounted to `/root/.claude/agents`, so the specialist agents (orchestrator, data-layer, frontend, etc.) are registered for Claude Code inside the container in addition to being discovered from `/workspace`.
- **Network mode**: default `bridge` (outbound allowed; no host network, no extra published ports beyond 8080/5173)
- **User**: container runs as root (base image default). No additional capabilities or privileged mode.

### Claude Code auth persistence

Claude Code stores its OAuth credentials in `~/.claude/.credentials.json` (note the leading dot on `.credentials.json` — it is a hidden file). The container's entrypoint links `/root/.claude/.credentials.json` to `/claude-auth/.credentials.json`, so credentials you create inside the container persist across rebuilds in the `claude-auth` named volume. Authenticate once inside the container with `claude` and the login survives.

Alternative — reuse the host's existing login inside the container (shares host auth and writes token refreshes back to the host):

```bash
docker run -it --rm \
  -v "${PWD}:/workspace" \
  -v "$HOME/.claude/.credentials.json:/root/.claude/.credentials.json" \
  -w /workspace \
  builders-box
```

Note this exposes that single credential file to the container, unlike the baseline below.

## Local MySQL (host)

```sql
CREATE USER 'buildersbox'@'%' IDENTIFIED BY 'pick-a-password';
GRANT ALL PRIVILEGES ON flexpath_final.* TO 'buildersbox'@'%';
FLUSH PRIVILEGES;
```

Inside the container, set:

```bash
export DB_USERNAME=buildersbox
export DB_PASSWORD='pick-a-password'
export DB_URL=jdbc:mysql://host.docker.internal:3306/flexpath_final
```

(Use `host.docker.internal` on Docker Desktop; on Linux use the host IP or `--add-host`.)

## Smoke test

```bash
# Inside the container
java -version
mvn -version
node -version
ls /workspace
```

**Observed output** (paste your actual run here):

```
openjdk version "17.0.x" ...
Apache Maven 3.x.x ...
v18.x.x
... project files listed ...
```

## Security decisions (provisional)

- **Filesystem**: only the project directory is mounted. Home, SSH, credentials, and Downloads are not visible inside the container.
- **Network**: bridge mode with two explicit ports. No host networking. Outbound access exists for package installs and AI tools but is not further restricted at this stage.
- **Credentials**: DB password is supplied via environment variables at runtime, not baked into the image. No cloud keys or SSH keys are mounted.
- **Persistence**: source changes persist via the `/workspace` volume. `/tmp` and container-only caches are ephemeral.
- **Tools**: Java 17, Maven, Node, MySQL client, Claude Code, and OpenCode are present because the project needs them. Additional tools or mounts will be added only when a concrete project task requires them.

These choices are a baseline for the course and will be revisited as the agent needs evolve.