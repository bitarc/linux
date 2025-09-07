# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ -r /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# Bash specific prompt and environment
PS1='\[\e[1;33m\]\h\[\e[0m\] \[\e[1;32m\]\u\[\e[0m\]\[\e[1;35m\]:\w\$\[\e[0m\] '

if [ -f ~/.aliases ]; then
    source ~/.aliases
fi
