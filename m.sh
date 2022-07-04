#!/usr/bin/env bash

# This shell script wrapper is meant to go somewhere in your path.
# For me this is ~/bin. Edit the lines below to make it work.
# See MyCLI install instructions for more information.

# !!! Edit this line to point to the location of your MyCLI clone
export MYCLI_EXEC_REPO="$HOME/projects/MyCLI"

# !!! Edit this line to make sure you will use the right ruby version
#     This line may be different depending on your environment
export RBENV_VERSION=3.0.1

# If the command returns an error we split the string into single letter
# commands and try again. This let's us use `m tcb bob` instead of
# `m t c b bob`.
# !!! WARNING. This retries for ANY failure, not just command not found.
export MYCLI_RETRY_ON_ERROR=0

# !!! No need (hopefully) to edit below this line.
# --------------------------------------------------------------------

ruby ${MYCLI_EXEC_REPO}/m.rb "$@"
retval=$?

if [[ $retval -ne 0 ]] && [[ $MYCLI_RETRY_ON_ERROR -eq 1 ]]; then
  first=$1
  shift
  args=()
  for ((i = 0; i < ${#first}; i++)); do
    args+=("${first:$i:1}")
  done
  args+=("$@")
  echo "Retrying as: m ${args[@]}..."
  ruby ${MYCLI_EXEC_REPO}/m.rb "${args[@]}"
fi
