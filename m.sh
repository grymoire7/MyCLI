#!/usr/bin/env zsh

# This shell script wrapper is meant to go somewhere in your path.
# For me this is ~/bin. Edit the lines below to make it work.
# See MyCLI install instructions for more information.

# !!! Edit this line to point to the location of your MyCLI clone
export MYCLI_EXEC_REPO="$HOME/bin/MyCLI"

# !!! Edit this line to make sure you will use the right ruby version
#     This line may be different depending on your environment
export RBENV_VERSION=3.0.1

ruby ${MYCLI_EXEC_REPO}/m.rb "$@"
