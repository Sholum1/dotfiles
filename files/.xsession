#!/bin/sh

# Disable access control for the current user
xhost +SI:localuser:$USER

# Keyboard in abnt2
setxkbmap -layout br -variant abnt2
xmodmap ~/.Xmodmap

# Run the screen compositor
picom &

# Enable the screen locker
xss-lock -- slock &

# Fire it up
exec dbus-launch --exit-with-session emacs -mm --debug-init --use-exwm --with-profile=default
