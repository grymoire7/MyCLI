#!/usr/bin/env bash
# These lines are like an unofficial strict mode.
# See https://dev.to/thiht/shell-scripts-matter for details.
set -euo pipefail
IFS=$'\n\t'

#/ Usage:
#/     example_script [--help] [-c|--country <country_name>]
#/                    [-e|--emphasis]
#/
#/ Description:
#/     Skeleton bash script as example of "best practices".
#/
#/ Options:
#/   --help                    : Display this help message
#/   -c|--country country_name : Specify country name
#/   -e|--emphatic             : Say it with emphasis
#/
#/ Examples:
#/     example_script --help   # see this help
#/     example_script          # say hello
#/     example_script -e       # say it emphatically
#/     example_script -c Cuba  # say it from Cuba
#/
#/ References:
#/     * https://github.com/bahamas10/bash-style-guide
#/     * https://dev.to/thiht/shell-scripts-matter
#/     * https://google.github.io/styleguide/shell.xml

# Print all lines starting with '#/' as usage when --help is seen as an
# argument.
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

# A quick collection of logging functions
# On a unix box you might want to write log files to /tmp instead.
# Add time/date etc. to taste.
readonly LOG_FILE="./$(basename "$0").log"   # readonly is like const
info()    { echo "[INFO]    " "$@" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo "[WARNING] " "$@" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo "[ERROR]   " "$@" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo "[FATAL]   " "$@" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }

# globals -- try to keep these to a minimum
COUNTRY='Canada'                   # set a default country
EMPHASIS=0                         # set default emphasis

# Prefer functional programming.
main() {

    # -------------------------------------------------------------------------
    # Here is one way to handle command line arguments. You may want to try
    # getopts for more complicated options handling. (Google it.)
    #
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--country)          # an option that takes one argument
                COUNTRY="$2"       # grab the argument
                shift              # shift on by
                ;;
            -e|--emphatic)         # an option that takes NO argumets
                EMPHASIS=1         # be emphatic, no shifting
                ;;
        esac
        shift                      # shift to next argument
    done
    # -------------------------------------------------------------------------

    local w='Earth'                # prefer locals variable in functions
    echo 'Hello world.'            # string literals use single quotes
    echo "Hello $w."               # interpreted strings use double quotes
    greet 'Alice'                  # call a function with parameter
    greet                          # call a function without parameter
}

############################################################
# Display greeting
# Also, an example for more complete function comments from
# Google's coding standards for shell scripts.
# Globals:
#     COUNTRY
#     EMPHASIS
# Arguments:
#     $1 - name of person to greet, optional
# Returns:
#     None
############################################################
greet() {
    # provide defaults for arguments per strict mode
    local my_arg=${1:-"stranger"}
    if [[ $EMPHASIS -eq 1 ]]; then
        echo "Hi $my_arg. Welcome to $COUNTRY!!!"
    else
        echo "Hi $my_arg. Welcome to $COUNTRY."
    fi
}

# This method is run before the script exits. Like 'finally' for your script.
cleanup() {
    # Remove temporary files
    # Restart services
    # ...
    info "Cleaning up..."
}

# This conditional executes main only if script is called directly,
# not if it's sourced from another script.
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap cleanup EXIT     # trap exit and call cleanup()
    main "$*"             # do the main thing
fi


