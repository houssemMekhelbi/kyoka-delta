# ~/.config/zsh/kyoka-delta.zsh-theme
# Kyoka prompt: agnoster's segment chain, recoloured, standalone (no oh-my-zsh).
# Segments are cut with a "/" slant (U+E0BC) so they lean like the bar panes.
#   status  Rose, only on failure / root / background jobs
#   context Raised + Pewter, only over SSH or as another user
#   dir     Indigo + Frost
#   git     Violet when clean (▱ branch), Ice with ± when dirty (▰ branch)
# Hex colours need zsh 5.7+ and a true-colour terminal; the slant needs a Nerd Font.

setopt prompt_subst

KYOKA_DEFAULT_USER=${KYOKA_DEFAULT_USER:-rahal}   # hide context on your own box

K_RAISED='#1B1729' K_INDIGO='#263B8F' K_VIOLET='#4A30A6'
K_PEWTER='#9A92C4' K_ICE='#8FE3F2'    K_FROST='#ECEAF5'
K_ROSE='#B83A5E'   K_VOID='#08070D'   K_HAIR='#4A4560'

KYOKA_SEP=$'\ue0bc'
typeset -g KYOKA_BG=NONE

kyoka_segment() {
  local bg="%K{$1}" fg="%F{$2}"
  if [[ $KYOKA_BG != NONE && $1 != $KYOKA_BG ]]; then
    print -n "%{$bg%F{$KYOKA_BG}%}$KYOKA_SEP%{$fg%} "
  else
    print -n "%{$bg%}%{$fg%} "
  fi
  KYOKA_BG=$1
  [[ -n $3 ]] && print -n -- "$3 "
}

kyoka_end() {
  if [[ $KYOKA_BG != NONE ]]; then
    print -n "%{%k%F{$KYOKA_BG}%}$KYOKA_SEP"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  KYOKA_BG=NONE
}

# ~/dotfiles/hypr -> ~/d/hypr
kyoka_short_pwd() {
  local p=${(%):-%~}
  local -a parts=("${(@s:/:)p}")
  local i
  for (( i = 1; i < ${#parts}; i++ )); do
    [[ -z ${parts[i]} || ${parts[i]} == '~' ]] && continue
    if [[ ${parts[i]} == .* ]]; then
      parts[i]=${parts[i][1,2]}
    else
      parts[i]=${parts[i][1]}
    fi
  done
  print -rn -- "${(j:/:)parts//\%/%%}"
}

kyoka_status() {
  local -a s
  (( KYOKA_RETVAL != 0 )) && s+="✘ $KYOKA_RETVAL"
  (( UID == 0 )) && s+="%F{$K_ICE}⚡%F{$K_FROST}"
  [[ -n ${jobstates} ]] && s+="%F{$K_ICE}⚙%F{$K_FROST}"
  (( ${#s} )) && kyoka_segment $K_ROSE $K_FROST "${(j: :)s}"
}

kyoka_context() {
  [[ $USER != $KYOKA_DEFAULT_USER || -n $SSH_CONNECTION ]] &&
    kyoka_segment $K_RAISED $K_PEWTER '%n@%m'
}

kyoka_dir() {
  kyoka_segment $K_INDIGO $K_FROST "$(kyoka_short_pwd)"
}

kyoka_git() {
  command git rev-parse --is-inside-work-tree &>/dev/null || return
  local ref
  ref=$(command git symbolic-ref --short HEAD 2>/dev/null) ||
    ref="➦ $(command git rev-parse --short HEAD 2>/dev/null)"
  ref=${ref//\%/%%}
  if [[ -n $(command git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n1) ]]; then
    kyoka_segment $K_ICE $K_VOID "▰ $ref ±"
  else
    kyoka_segment $K_VIOLET $K_FROST "▱ $ref"
  fi
}

kyoka_build_prompt() {
  kyoka_status
  kyoka_context
  kyoka_dir
  kyoka_git
  kyoka_end
}

kyoka_precmd() { KYOKA_RETVAL=$? }
autoload -Uz add-zsh-hook
add-zsh-hook precmd kyoka_precmd

PROMPT='%{%f%b%k%}$(kyoka_build_prompt) '
RPROMPT="%F{$K_HAIR}%*%f"

# ---- completion ------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors 'ma=48;2;27;23;41;38;2;236;234;245'

# ---- plugins ---------------------------------------------------------
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$K_HAIR"
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting must be sourced last, then styled.
if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ZSH_HIGHLIGHT_STYLES[command]='fg=#8B6CF0'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#8B6CF0'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#8B6CF0'
  ZSH_HIGHLIGHT_STYLES[function]='fg=#8B6CF0'
  ZSH_HIGHLIGHT_STYLES[precommand]='fg=#8B6CF0,underline'
  ZSH_HIGHLIGHT_STYLES[path]='fg=#ECEAF5'
  ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#5FBFD6'
  ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#5FBFD6'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#8FE3F2'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#8FE3F2'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#F07F9A,underline'
fi

export FZF_DEFAULT_OPTS="--color=bg+:#1B1729,fg:#A29DBA,fg+:#ECEAF5,hl:#8B6CF0,hl+:#8FE3F2,pointer:#8FE3F2,prompt:#8FE3F2,info:#9A92C4,border:#8B6CF0 --pointer='◢' --border=sharp"
