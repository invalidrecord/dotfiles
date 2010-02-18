. ~/.zsh/config
. ~/.zsh/aliases
. ~/.zsh/completion

# use .localrc for settings specific to one system
[[ -f ~/.localrc ]] && .  ~/.localrc

if [[ -s /Users/jschoolcraft/.rvm/scripts/rvm ]] ; then source /Users/jschoolcraft/.rvm/scripts/rvm ; fi