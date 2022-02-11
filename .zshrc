setopt prompt_subst
autoload -Uz vcs_info # enable vcs_info
zstyle ':vcs_info:git*' formats '%b' # format $vcs_info_msg_0_

DISABLE_AUTO_TITLE="true"
NEWLINE=$'\n'
PS1='$(prompt-directory)$(prompt-git-branch)$(prompt-git-status)${NEWLINE}$(prompt-user)$(prompt-cursor) '

# split history files based on session
HISTFILE="$HOME/.zsh_histories/.zsh_history.$(date +%s)_$(basename `tty`)"
HISTSIZE=99999
SAVEHIST=99999

# workspace
export WORKSPACE="$HOME/workspace"

# autojump
# [ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
source $WORKSPACE/personal/j/j.sh

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# rbenv
eval "$(rbenv init -)"

# postgres app
export PG_VERSION=13
export PGHOST=localhost
export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/$PG_VERSION/bin"

# ncurses (for cbonsai)
export PATH="/usr/local/opt/ncurses/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/ncurses/lib"
export CPPFLAGS="-I/usr/local/opt/ncurses/include"
export PKG_CONFIG_PATH="/usr/local/opt/ncurses/lib/pkgconfig"

alias de='docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)"'
alias dps='docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Status}}" | sort'
alias ls="ls -alGF"
alias pbsquish="pbpaste | tr '\n' ' ' | pbcopy"
alias cd-w="cd $WORKSPACE"

# java (for android studio)
export PATH="/usr/local/opt/openjdk/bin:$PATH"

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# include doximity config
source $HOME/.doxrc

# enable shell completion
dox completion zsh > "${fpath[1]}/_dox"

# utilities

function is-git() {
  [ -n "$vcs_info_msg_0_" ] && true || false
}

function is-me() {
  [ "`whoami`" = "david" ] && true || false
}

function launch() {
  open -a "$1"
}

function password-set() {
  security add-generic-password -a "$USER" -s "$1" -w
}

function password-get() {
  security find-generic-password -a "$USER" -s "$1" -w
}

# always loaded before displaying the prompt
function precmd() {
  vcs_info
  title "$(relative-pwd)"
}

function prompt-cursor() {
  echo -n "%F{254}➜%f"
}

function prompt-directory() {
  echo -n "%F{#ba6ecf}$(relative-pwd)%F{252}"
}

function prompt-git-branch() {
  ! is-git && return

  local branch="$vcs_info_msg_0_"

  branch="${branch#heads/}"
  branch="${branch/.../}"

  echo -n " on %F{#f1502f}$branch%F{252}"
}

function prompt-git-status() {
  ! is-git && return

  local prompt=""
  local output="$(git status --porcelain -b 2> /dev/null)"

  grep -Eq '^\?\? ' <(<<<$output) && prompt+="?" # untracked
  grep -Eq '^(A[ MDAU]|M[ MD]|UA) ' <(<<<$output) && prompt+="+" # added
  grep -Eq '^([ MARC]M|^R[ MD]) ' <(<<<$output) && prompt+="!" # modified
  grep -Eq '^([MARCDU ]D|D[ UM]) ' <(<<<$output) && prompt+="-" # deleted

  [ -z "$prompt" ] && return

  echo -n " $prompt"
}

function prompt-user() {
  ! is-me && echo -n "as %F{#ba6ecf}%n%F{252} "
}

function relative-pwd() {
  local dir="`pwd`"

  if [[ "$dir" =~ "$WORKSPACE" ]] && [[ "$dir" != "$WORKSPACE" ]]
  then
    echo -n "${dir#"$WORKSPACE/"}"
  elif
  then
    print -P "%~"
  fi
}

function set_env() {
  if [ -z "$1" ]
  then
    echo "Missing environment variable name" && return 1
  fi

  printf "Enter secret: "
  eval "read -s $1 && export $1"
}

function quit() {
  osascript -e "quit app \"$1\""
}

function title() {
  echo -en "\033]0;${1:?zsh}\007"
}

function window() {
  ([ -z "$1" ] || [ -z "$2" ]) && return

  defaults write com.knollsoft.Rectangle specifiedHeight -float $2
  defaults write com.knollsoft.Rectangle specifiedWidth -float $1

  quit Rectangle
  launch Rectangle

  echo "Rectangle window size updated to $1x$2."
}

# must be after function definitions
export GITHUB_TOKEN="$(password-get github_token)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh