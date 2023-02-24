#!/bin/sh

# Keyboard in abnt2
setxkbmap -layout br -variant abnt2
xmodmap ~/.Xmodmap

# Run the screen compositor
picom &

# Enable the screen compositor
xss-lock -- slock &

# Fire it up
exec emacs -mm --debug-init
