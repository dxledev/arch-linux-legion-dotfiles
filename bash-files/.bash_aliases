### custom aliases

# bash and nvim
alias vim='nvim'
alias edit-bash='nvim ~/.zshrc'
alias rel-bash='source ~/.zshrc'
alias bashrc='edit-bash'
alias vsbashrc='code ~/.bashrc'
alias editbash='edit-bash'
alias bashrel='rel-bash'
alias relbash='rel-bash'
alias bash-aliases='vim ~/.bash_aliases'
alias edit-bash-aliases="bash-aliases"
alias bashaliases='bash-aliases'
alias vi='nvim'
alias nv='nvim'
alias neovim='nvim'
alias bashenv='nvim ~/.bash_env'

# zsh
alias relzsh='source ~/.zshrc'
alias rel-z='source ~/.zshrc'
alias relz='source ~/.zshrc'
alias edit-z='nvim ~/.zshrc'

# git
alias git-log='git log --oneline --abbrev-commit --all --graph --decorate --color'
alias lg='lazygit'

# ls
alias ll='eza --icons --color=always -l'
alias la='eza --icons --color=always -a'
alias l='eza --icons --color=always'
alias ls='eza --icons --color=always -l'
alias lla='eza --icons --color=always -la'

# grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# venv
alias in-venv='[ -n "$VIRTUAL_ENV" ] && echo "venv ON" || echo "venv OFF"'

# themes
alias themesdir='cd ~/.config/themes'

# fastfetch
alias ff2='fastfetch -l arch_small --config nyarch'
alias ff='fastfetch -l arch2'

# show the date
alias da='date "+%Y-%m-%d %A %T %Z"'

# directories
alias home='cd /home/dxle'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias .....='cd ../../..'
alias ......='cd ../../../..'

# bat
alias bat='bat --theme ansi'

# fd-nvim
alias fd-nvim='fd --type f --hidden --exclude .git | fzf | xargs -r nvim'

# open image
alias view-image='~/bin/launch-image-viewer'
alias open-image='~/bin/launch-image-viewer'
alias imv='~/bin/launch-image-viewer'

# open file explorer
alias fe='~/bin/launch-file-explorer'

# global open
alias open='~/bin/open-file'
alias start='~/bin/open-file'

# files
alias cp='cp -i'
alias mv='mv -i'
alias rm='trash -v'
alias trash-empty='trash-empty --trash-dir ~/.local/share/Trash'
alias mkdir='mkdir -p'
alias ping='ping -c 10'
alias less='less -R'
alias ps='ps auxf'

# terminal aesthetics
alias activity='btop'
alias um='unimatrix'
alias pipes='pipes.sh'
alias aquarium='asciiquarium'
alias bonsai='cbonsai'
alias clock='tty-clock -c'
alias train='sl'
alias random-pokemon='pokemon-colorscripts -r -b'

# browser
alias firefox='~/bin/launch-firefox'
