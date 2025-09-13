#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return
export LANG=en_US.UTF-8
export VISUAL=vim
export EDITOR=vim
export TERM=xterm-256color
. "/home/huai/.acme.sh/acme.sh.env"
PS1='\[\e[1;33m\]\h\[\e[0m\] \[\e[1;32m\]\u\[\e[0m\]\[\e[1;35m\]:\w\$\[\e[0m\] '

if [ -f ~/.aliases ]; then
    source ~/.aliases
fi