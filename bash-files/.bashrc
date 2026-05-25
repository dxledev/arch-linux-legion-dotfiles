#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

if [ -f ~/.bash_env ]; then
  . ~/.bash_env
fi

if [ -f ~/.bash_functions ]; then
  . ~/.bash_functions
fi

# print_newline_if_needed() {
#   if [ -n "$LAST_PROMPT" ]; then
#     echo
#   fi
#   LAST_PROMPT=1
# }
#
# __force_prompt() {
#   return 0
# }

# PROMPT_COMMAND="print_newline_if_needed"

# word movement
bind '"\ew": forward-word'
bind '"\eb": backward-word'

# start/end of line
bind '"\e0": beginning-of-line'
bind '"\ee": end-of-line'

# delete word forward
bind '"\ed": kill-word'

# Enable bash completion
[[ -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind 'set menu-complete-display-prefix on'
bind '"\t": menu-complete'
bind '"\e[Z": menu-complete-backward'

# set up fzf fuzzy completion
source <(fzf --bash)

eval "$(starship init bash)"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/dxle/.lmstudio/bin"
# End of LM Studio CLI section

export OPENAI_BASE_URL="http://localhost:1234/v1"
export OPENAI_API_KEY="lm-studio"


# Added by Antigravity CLI installer
export PATH="/home/dxle/.local/bin:$PATH"
