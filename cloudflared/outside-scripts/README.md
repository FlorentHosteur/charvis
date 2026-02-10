# Outside Scripts

Host-side helper scripts for interacting with the running OpenClaw containers.

## Setup

Add this folder to your PATH or create aliases:

```bash
# Option A: add to PATH
export PATH="/path/to/Charvis/outside-scripts:$PATH"

# Option B: create an alias
alias sh-openclaw='/path/to/Charvis/outside-scripts/sh-openclaw'
```

Make the scripts executable (one-time):

```bash
chmod +x /path/to/Charvis/outside-scripts/sh-openclaw
```

## Scripts

### sh-openclaw

Opens an interactive OpenClaw shell inside the running `rag-openclaw` container.

**Prerequisites:** The container must be running.

```bash
# Start the stack
docker compose up -d

# Attach to OpenClaw
sh-openclaw
```

If the container is not running, the script will print an error and exit.
