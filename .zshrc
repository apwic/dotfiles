# -------------------------------
# 0. Dotfiles (bare repo)
# -------------------------------
alias dotfiles='git --git-dir=/Users/adiyansawicaksana/dotfiles/ --work-tree=/Users/adiyansawicaksana'

# -------------------------------
# 1. Environment
# -------------------------------
export ZDOTDIR="$HOME"
export EDITOR="nvim"

# -------------------------------
# 2. PATH (keep it explicit, no duplicates)
# -------------------------------
export PATH="$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# -------------------------------
# 3. History
# -------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space

# -------------------------------
# 4. Completion
# -------------------------------
autoload -Uz compinit
compinit

# -------------------------------
# 5. Keybindings (optional)
# -------------------------------
# bindkey -e  # enable if you want emacs-style
bindkey '^Y' autosuggest-accept

# -------------------------------
# 6. Plugins (Sheldon)
# -------------------------------
command -v sheldon >/dev/null && eval "$(sheldon source)"

# -------------------------------
# 7. Tools
# -------------------------------

# better cd
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# direnv (optional)
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# -------------------------------
# 8. Prompt (Starship)
# -------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

# -------------------------------
# 9. Aliases (keep small)
# -------------------------------
alias ll="ls -lah"
alias cfg="cd ~/.config/"

