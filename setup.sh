#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
OUTSIDE_SCRIPTS="$SCRIPT_DIR/outside-scripts"
SHELL_RC=""

# ── Helpers ──────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo "============================================"
  echo "  RAG OpenClaw Setup"
  echo "============================================"
  echo ""
}

detect_shell_rc() {
  case "$(basename "$SHELL")" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bashrc" ;;
    *)    SHELL_RC="$HOME/.profile" ;;
  esac
}

prompt_optional() {
  local var_name="$1"
  local label="$2"
  local value=""
  read -rp "$label (leave empty to skip): " value
  if [ -n "$value" ]; then
    echo "$var_name=$value"
  fi
}

prompt_mandatory() {
  local var_name="$1"
  local label="$2"
  local value=""
  while [ -z "$value" ]; do
    read -rp "$label (required): " value
    if [ -z "$value" ]; then
      echo "  This field is required. Please try again."
    fi
  done
  echo "$var_name=$value"
}

generate_token() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    head -c 32 /dev/urandom | xxd -p | tr -d '\n'
  fi
}

# ── Main ─────────────────────────────────────────────────────────────

print_header
detect_shell_rc

echo "This script will configure your RAG OpenClaw environment."
echo "It will create a .env file, generate tokens, set up SSH keys,"
echo "and add helper scripts to your PATH."
echo ""

# ── Step 1: Collect environment variables ────────────────────────────

echo "── Step 1/5: Environment Variables ──"
echo ""

ANTHROPIC_LINE=$(prompt_optional "ANTHROPIC_API_KEY" "Anthropic API key (sk-ant-...)")
OPENAI_LINE=$(prompt_optional "OPENAI_API_KEY" "OpenAI API key (sk-...)")
KIMI_LINE=$(prompt_optional "KIMI_API_KEY" "Kimi API key (sk-...)")
GH_LINE=$(prompt_optional "GH_TOKEN" "GitHub token (ghp_...)")

echo ""
CLOUDFLARE_LINE=$(prompt_mandatory "CLOUDFLARE_TUNNEL_TOKEN" "Cloudflare Tunnel token")

# ── Step 2: Generate OpenClaw gateway token ──────────────────────────

echo ""
echo "── Step 2/5: Generating OpenClaw Gateway Token ──"
echo ""

GATEWAY_TOKEN=$(generate_token)
echo "  Generated token: $GATEWAY_TOKEN"

# ── Step 3: Write .env file ──────────────────────────────────────────

echo ""
echo "── Step 3/5: Writing .env ──"
echo ""

{
  [ -n "$ANTHROPIC_LINE" ] && echo "$ANTHROPIC_LINE"
  [ -n "$OPENAI_LINE" ] && echo "$OPENAI_LINE"
  [ -n "$GH_LINE" ] && echo "$GH_LINE"
  echo "$CLOUDFLARE_LINE"
  echo ""
  echo "# OpenClaw"
  echo "OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN"
  echo "OPENCLAW_GATEWAY_PORT=18789"
  echo "OPENCLAW_BRIDGE_PORT=18790"
  [ -n "$KIMI_LINE" ] && echo "" && echo "# Kimi CLI" && echo "$KIMI_LINE"
} > "$ENV_FILE"

echo "  Written to $ENV_FILE"

# ── Step 4: Generate SSH key pair ────────────────────────────────────

echo ""
echo "── Step 4/5: SSH Key Generation ──"
echo ""

SSH_DIR="$SCRIPT_DIR/.ssh-agent"
SSH_KEY="$SSH_DIR/id_ed25519"

if [ -f "$SSH_KEY" ]; then
  echo "  SSH key already exists at $SSH_KEY"
else
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  ssh-keygen -t ed25519 -C "agent@openclaw" -f "$SSH_KEY" -N ""
  echo "  SSH key generated at $SSH_KEY"
fi

SSH_PUB_KEY=$(cat "${SSH_KEY}.pub")

# ── Step 5: Set up host helper scripts ───────────────────────────────

echo ""
echo "── Step 5/5: Host Helper Scripts ──"
echo ""

chmod +x "$OUTSIDE_SCRIPTS"/*
echo "  Made scripts in outside-scripts/ executable"

# Add to PATH if not already present
if ! grep -q "$OUTSIDE_SCRIPTS" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# RAG OpenClaw helper scripts" >> "$SHELL_RC"
  echo "export PATH=\"$OUTSIDE_SCRIPTS:\$PATH\"" >> "$SHELL_RC"
  echo "  Added $OUTSIDE_SCRIPTS to PATH in $SHELL_RC"
else
  echo "  PATH already configured in $SHELL_RC"
fi

# Source the updated shell config
export PATH="$OUTSIDE_SCRIPTS:$PATH"

# ── Done ─────────────────────────────────────────────────────────────

echo ""
echo "============================================"
echo "  Setup Complete"
echo "============================================"
echo ""
echo "── Start the stack ──"
echo ""
echo "  cd $SCRIPT_DIR"
echo "  docker compose up -d"
echo ""
echo "── Connect via terminal ──"
echo ""
echo "  sh-openclaw"
echo ""
echo "  (or: docker exec -it rag-openclaw bash)"
echo ""
echo "── Connect via HTTPS gateway ──"
echo ""
echo "  URL:   https://<your-subdomain>.<your-domain>"
echo "  Token: $GATEWAY_TOKEN"
echo ""
echo "  Configure the public hostname in Cloudflare Zero Trust:"
echo "    Type: HTTP  |  URL: rag-openclaw:18789"
echo ""
echo "── SSH public key (add to GitHub/GitLab) ──"
echo ""
echo "  $SSH_PUB_KEY"
echo ""
echo "── Local file ──"
echo ""
echo "  $SSH_KEY.pub"
echo ""
echo "============================================"
echo ""
echo "To apply PATH changes in your current shell, run:"
echo ""
echo "  source $SHELL_RC"
echo ""
