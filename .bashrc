#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

eval "$(zoxide init bash --cmd cd)"
export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"
eval "$(oh-my-posh init bash --config ~/.config/ohmyposh/poisson.omp.json)"
