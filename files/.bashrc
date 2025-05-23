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
alias arruma-teclado='setxkbmap -layout br -variant abnt2 && xmodmap ~/.Xmodmap'
alias zougue-vm='quickemu --vm ~/sata/VM/archlinux-latest.conf'
alias | sed -E "s/^alias ([^=]+)='(.*)'$/alias \1 \2 \$*/g; s/'\\\''/'/g;" >~/.dotfiles/files/.emacs.d/eshell/alias

# Eat integration
[ -n "$EAT_SHELL_INTEGRATION_DIR" ] && \
  source "$EAT_SHELL_INTEGRATION_DIR/bash"
