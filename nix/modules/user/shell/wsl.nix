{
  pkgs,
  lib,
  secrets,
  isDarwin,
  isWSL,
  ...
}:
{
  home = {
    sessionVariables = { };

    shellAliases = {
      npp = "notepad++.exe";
      gcli = ''powershell.exe -command "Get-Clipboard"'';
      scli = "clip.exe";
      exp = "explorer.exe";
      wcode = "cmd.exe /c 'code .'";
    };
  };

  programs.zsh = {
    initContent = ''
      SSH_AUTH_TMPDIR="/home/rubikoid/.ssh"
      export REAL_WSL_ADDR=`netsh.exe interface ip show ipaddresses "vEthernet (WSL)" | head -n 2 - | tail -n 1 | awk '{ print $2; }'`
      export INTR_WSL_ADDR=`ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`

      redo_ssh_wsl2() {
        # also setup ssh, but for wsl2
        if [ -z "$SSH_AUTH_SOCK" ]; then
          export SSH_AUTH_SOCK="$SSH_AUTH_TMPDIR/agent"
          if [ ! -e "$SSH_AUTH_SOCK" ]; then
            echo "ssh socket ($SSH_AUTH_SOCK) not found"
            socat UNIX-LISTEN:$SSH_AUTH_SOCK,mode=0600,fork,shut-down EXEC:"/mnt/c/Code/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork >/dev/null 2>&1 &
          fi
        fi
        echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
      }

      redo_ssh_wsl2 || echo "smthing wrong with ssh_auth_sock";
    '';

    oh-my-zsh = {
      plugins = [ ];
    };
  };
}
