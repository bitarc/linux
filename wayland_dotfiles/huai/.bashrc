# If not running interactively, don't do anything
[[ $- != *i* ]] && return
# 自动启动 ssh-agent 并添加 id_ed25519 密钥（如未添加）
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
# ssh-add -l 2>/dev/null | grep -q id_ed25519 || ssh-add ~/.ssh/id_ed25519 2>/dev/null

[[ -r /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# Bash specific prompt and environment
PS1='\[\e[1;33m\]\h\[\e[0m\] \[\e[1;32m\]\u\[\e[0m\]\[\e[1;35m\]:\w\$\[\e[0m\] '
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export VISUAL=vim
export EDITOR=vim
export TERM=xterm-256color

# 加载通用别名
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi
umask 027