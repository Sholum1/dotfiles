# Bash initialization for interactive non-login shells and
# for remote shells (info "(bash) Bash Startup Files").

# Export 'SHELL' to child processes.  Programs such as 'screen'
# honor it and otherwise use /bin/sh.
export SHELL

if [[ $- != *i* ]]
then
    # We are being invoked from a non-interactive shell.  If this
    # is an SSH session (as in "ssh host command"), source
    # /etc/profile so we get PATH and other essential variables.
    [[ -n "$SSH_CLIENT" ]] && source /etc/profile

    # Don't do anything else.
    return
fi

# Source the system-wide file.
[ -f /etc/bashrc ] && source /etc/bashrc

# Aliases
alias ls='ls -p --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias docker='podman'
alias 'docker-compose'='podman-compose'
alias arruma-teclado='setxkbmap -layout br -variant abnt2 && xmodmap ~/.Xmodmap'
alias podman-socket='{ [ -S /tmp/podman.sock ] && pkill -f "podman system service.*unix:///tmp/podman.sock" && rm -f /tmp/podman.sock; }; sudo rm -f /var/run/docker.sock; podman system service --time=0 unix:///tmp/podman.sock & sleep 0.1 && sudo ln -sf /tmp/podman.sock /var/run/docker.sock'
alias sdk-container='guix shell --container --emulate-fhs --network bash curl zip unzip which coreutils tar gzip grep sed nss-certs findutils gcc zlib libxext libxrender libxtst libxi just --share=$HOME --preserve='^HOME$' --preserve='^DISPLAY$'--preserve='^XAUTHORITY$' --expose=$XAUTHORITY -- bash --rcfile ~/.dotfiles/files/.sdkbashrc'
alias | sed -E "s/^alias ([^=]+)='(.*)'$/alias \1 \2 \$*/g; s/'\\\''/'/g;" >~/.dotfiles/files/.emacs.d/eshell/alias

# Eat integration
[ -n "$EAT_SHELL_INTEGRATION_DIR" ] && \
  source "$EAT_SHELL_INTEGRATION_DIR/bash"
