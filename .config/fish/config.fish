if type -q starship
	eval (starship init fish)
end

set fish_greeting

fish_vi_key_bindings

fish_add_path $HOME/scripts
fish_add_path /usr/local/sbin

export VISUAL=vim
export EDITOR="$VISUAL"

export TERM=screen-256color

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export DOCKER_SCAN_SUGGEST="false"

set -g fish_user_paths "/usr/local/opt/crowdin@3/bin" $fish_user_paths

if status is-interactive
    cd ~/Projects
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
