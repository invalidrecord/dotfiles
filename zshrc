. ~/.zsh/config
. ~/.zsh/aliases
. ~/.zsh/completion

# use .localrc for settings specific to one system
[[ -f ~/.localrc ]] && .  ~/.localrc

# export rvm_trace_flag=1
# set -x
 fortune
 export PATH="$HOME/narwhal/bin:$HOME/.gem/ruby/1.8:$PATH"
if [[ -s ~/.rvm/scripts/rvm ]] ; then source ~/.rvm/scripts/rvm -v; fi
