# Homebrew — put /opt/homebrew/bin ahead of /usr/bin (brew doctor PATH warning)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Docker Desktop CLI (macOS). No-op when the dir is absent (WSL/Linux).
if [[ -d "$HOME/.docker/bin" ]]; then
  case ":$PATH:" in
    *":$HOME/.docker/bin:"*) ;;
    *) export PATH="$PATH:$HOME/.docker/bin" ;;
  esac
fi

export PATH="$HOME/.local/bin:$PATH"
