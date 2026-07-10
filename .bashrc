#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR=vim
export SYSTEMD_EDITOR=$EDITOR
export WINELOADER="$HOME/.local/share/Steam/compatibilitytools.d/DW-Proton Latest/files/bin/wine"
export ANV_DEBUG=video-decode,video-encode

alias apple-music-decrypt='(cd "$HOME/apple-music/AppleMusicDecrypt" && uv run python main.py)'
alias apple-music-decrypt-vi='vim "$HOME/apple-music/AppleMusicDecrypt/config.toml"'

alias screen-wakeup='ydotool key 54:1 54:0'

alias ls='ls --color=auto'
alias ll='ls --color=auto -AlF --group-directories-first --time-style=+"%Y-%m-%d %H:%M:%S"'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

. "$HOME/.local/bin/env"

eval "$(starship init bash)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

eval "$(fzf --bash)"
bind -x '"\eOQ": __fzf_history__'
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

[[ -r /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/atarakima1/.lmstudio/bin"
# End of LM Studio CLI section

. "$HOME/.cargo/env"

source '/home/atarakima1/.bash_completions/isdb-scanner.sh'
alias nvitop="uvx nvitop"

export PATH="$PATH:$HOME/go/bin"


# Added by Antigravity CLI installer
export PATH="/home/atarakima1/.local/bin:$PATH"
