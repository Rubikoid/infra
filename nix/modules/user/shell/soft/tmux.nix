{ ... }:
{
  home.shellAliases.tmux = "tmux attach || tmux";
  programs.tmux = {
    enable = true;

    terminal = "screen-256color";
    keyMode = "vi";
    mouse = false;

    historyLimit = 10000;

    escapeTime = 0; # idk wtf is it, but it was in old config))0
    clock24 = true;

    extraConfig = ''
      # kinda hot-reload
      bind r source-file ~/.tmux.conf

      # select panels by alt+arrow
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # fancy splits
      bind '"' set-environment -F "SOURCE_PANE_PID" "#{pane_pid}" \; split-window \; set-environment -u "SOURCE_PANE_PID"
      bind % set-environment -F "SOURCE_PANE_PID" "#{pane_pid}" \; split-window -h \; set-environment -u "SOURCE_PANE_PID"

      # idk wtf is it
      bind t display "pid=#{pane_pid}"

      # https://stackoverflow.com/questions/18600188/home-end-keys-do-not-work-in-tmux
      # https://superuser.com/questions/401926/how-to-get-shiftarrows-and-ctrlarrows-working-in-vim-in-tmux
      # bind -n End send-key C-e
      # bind -n Home send-key C-a

      # https://stackoverflow.com/a/56420131
      unbind C-S
      bind C-Y set-window-option synchronize-panes\; display-message "synchronize-panes is now #{?pane_synchronized,on,off}"

      # https://stackoverflow.com/a/10553992/4371598
      bind -n C-k clear-history
    '';
  };
}
