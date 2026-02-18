fish_add_path $HOME/scripts
fish_add_path /usr/local/sbin
fish_add_path /opt/homebrew/bin
fish_add_path $HOME/Projects/yabai/bin
fish_add_path $HOME/Projects/skhd/bin

if type -q starship
	eval (starship init fish)
end

set fish_greeting

fish_vi_key_bindings

export VISUAL=vim
export EDITOR="$VISUAL"

export XDG_CONFIG_HOME="/Users/dean/.config/"

export TERM=screen-256color

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export DOCKER_SCAN_SUGGEST="false"
export DOTNET_CLI_TELEMETRY_OPTOUT="true"

export FZF_TMUX=1
export FZF_TMUX_OPTS="-p 80%"

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow \
    --exclude .git \
    --exclude node_modules \
    --exclude .npm \
    --exclude .cache \
    --exclude "*cache*" \
    --exclude .Trash \
    --exclude Applications \
    --exclude Library/Caches \
    --exclude Library/Logs \
    --exclude Library/Mail \
    --exclude Library/Safari \
    --exclude Library/Containers \
    --exclude vendor \
    --exclude undodir \
    --exclude __pycache__ \
    --exclude .venv \
    --exclude venv \
    --exclude target \
    --exclude Workspaces \
    --exclude build \
    --exclude dist \
    --exclude "*.app"'

set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

# Additional options for better UX
set -gx FZF_DEFAULT_OPTS '--height 80% --layout=reverse --border --preview "head -100 {}"'

alias ls='eza'

if status is-interactive
    create-ramdisk
end

function ssh
  set ps_res (ps -p (ps -p %self -o ppid= | xargs) -o comm=)
  if [ "$ps_res" = "tmux" ]
    tmux rename-window (echo "ssh:" (echo $argv | cut -d . -f 1))
    command ssh $argv
    tmux set-window-option automatic-rename "on" 1>/dev/null
  else
    command ssh $argv
  end
end

function yy
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		cd -- "$cwd"
	end
	rm -f -- "$tmp"
end
