# Homebrew — put /opt/homebrew/bin ahead of /usr/bin (brew doctor PATH warning)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/timopruesse/.docker/bin"
# End of Docker Desktop section.

export PATH="$HOME/.local/bin:$PATH"
