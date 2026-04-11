export PATH="$HOME/.local/bin:$PATH"

# Run Claude with Enterprise auth (unset Bedrock vars in case they're lingering)
claude () {
  unset CLAUDE_CODE_USE_BEDROCK
  unset AWS_PROFILE
  unset AWS_REGION
  command claude --model sonnet "$@"
}

# Wrapper that ensures AWS_PROFILE is set and SSO is valid before running Claude via Bedrock
claudeaws () {
  export CLAUDE_CODE_USE_BEDROCK=1
  export AWS_REGION=us-east-1
  export AWS_PROFILE="AWSAdministratorAccess-<YOUR_AWS_ACCOUNT_ID>"
  aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null 2>&1 || \
    aws sso login --profile "$AWS_PROFILE" >/dev/null
  command claude --model opus "$@"
}

# Auto-start tmux for fuzzy search support (new session per tab)
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
  tmux new-session
fi

# Report current directory to terminal via OSC 7 (for Ghostty new tab in same dir)
# This works through tmux by using passthrough sequences
function osc7_cwd() {
  if [[ -n "$TMUX" ]]; then
    # Passthrough to Ghostty via tmux
    printf '\ePtmux;\e\e]7;file://%s%s\e\\\e\\' "$HOST" "$PWD"
  else
    printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd osc7_cwd
osc7_cwd  # Run once at shell startup
