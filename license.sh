#!/usr/bin/env bash

# TODO The URL of the GLP3 License should be user configurable
# TODO In fact all URL identifying Licenses should be user configurable.
URL_GPL3=https://www.gnu.org/licenses/gpl-3.0.txt

AVAILABLE_LICENSES=(gpl3 mit)
CURL=/usr/bin/curl

TEMPFILE=$(mktemp)

WORKING_DIR=$(pwd)
SELECTED_LICENSE=
SELECTED_LICENSE_URL=$URL_GPL3
LICENSE_BASENAME=LICENSE
LICENSE_PATH=


main() {
    parse_args "$@"
    set -- "${POSARGS[@]}"
    parse_posargs "$@"

    # Check if the $LICENSE_PATH already exists, if the --force flag is in
    # effect overwrite, otherwise terminate with an exist status of 1
    debug Does the \$LICENSE_PATH already name an existing file?
    if [ -f "$LICENSE_PATH" ]; then
        debug yes
        debug Is the --force flag in effect?
        if [ "${FORCE:-}" ]; then
            debug yes
        else
            debug no
            fatal $(quote $LICENSE_PATH) already exists\; use --force to overwrite!
        fi
    else
        debug no
    fi

    # If a license has not been specified, request one interactively
    debug Has a the user selected a license through the --license option?
    if [ -z "$SELECTED_LICENSE" ]; then
        debug no
        debug select a license
        PS3='Select a license: '
        select SELECTED_LICENSE in ${AVAILABLE_LICENSES[@]}; do
            [ -n "$SELECTED_LICENSE" ] && break
        done
    else
        debug yes
    fi
    debug selected_licence: $SELECTED_LICENSE

    # TODO Get the URL of the $SELECTED_LICENSE from a configuration file
    # Download the LICENSE
    echo downloading $(quote $SELECTED_LICENSE) license \
         from $(quote $SELECTED_LICENSE_URL)
    $CURL --progress-bar --fail $URL_GPL3 > $TEMPFILE
    if [ $? -gt 0 ]; then
        debug FAILED download
        fatal failed to download $(quote $SELECTED_LICENSE) license from \
              $(quote $SELECTED_LICENSE_URL)
    else
        debug SUCCESSFULL download
        rm --force $LICENSE_PATH
        cp --force $TEMPFILE $LICENSE_PATH
        debug done!
        echo $LICENSE_PATH
    fi
}

parse_posargs() {
    # The role of the 1st positional argument is double.

    # In case $1 names a valid path it is interpreted as the $LICENSE_DIRNAME to
    # the $LICENSE_PATH. The $LICENSE_BASENAME in this case is provided through
    # the option --filename or its default value.
    #
    # In case $1 has been omitted, it is interpreted to mean the WORKING_DIR and
    # the same reasoning as the previous case is applied.
    #
    # In case $1 NOT being a valid path it is assumed that the user intended for
    # $1 to be interpreted as the $LICENSE_PATH. If the $LICENSE_PATH dirname
    # does exist then it becomes the $LICENSE_DIRNAME and the basename becomes
    # the $LICENSE_BASENAME. Otherwise the program stops execution with an exit
    # status of 1
    LICENSE_PATH="$(realpath --canonicalize-missing "${1:-$WORKING_DIR}")"
    local LICENSE_DIRNAME=

    debug Is the first positional argument a valid path?
    if [ -d "$LICENSE_PATH" 2>/dev/null ]; then
        debug $(quote $LICENSE_PATH) it is a valid path
        LICENSE_DIRNAME="$LICENSE_PATH"
    else
        debug $(quote $LICENSE_PATH) it is not a valid path
        if [ ! -d "$(dirname "$LICENSE_PATH")" ]; then
            debug $(quote $LICENSE_PATH) it is not even a valid dirname
            fatal $(quote $LICENSE_PATH) missing license path dirname!
        else
            debug $(quote $LICENSE_PATH) it is a license filename and a valid dirname
            LICENSE_BASENAME="${LICENSE_PATH##*/}"
            LICENSE_DIRNAME="${LICENSE_PATH%/*}"
        fi
    fi
    LICENSE_PATH="${LICENSE_DIRNAME}/${LICENSE_BASENAME}"
    debug license_basename: $LICENSE_BASENAME
    debug license_dirname: $LICENSE_DIRNAME
    debug license_path: $LICENSE_PATH
}

parse_args() {
    declare -ga POSARGS=()
    while (($# > 0)); do
        case "${1:-}" in
            -l | --license | --license=*)
                LICENSE="$(parse_param "$@")" || shift $?
                ;;
            -f | --force)
                FORCE=0
                ;;
            -d | --debug)
                DEBUG=0
                debug arguments: "$@"
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            -[a-zA-Z][a-zA-Z]*)
                local i="${1:-}"
                shift
                local rest="$@"
                set --
                for i in $(echo "$i" | grep -o '[a-zA-Z]'); do
                    set -- "$@" "-$i"
                done
                set -- $@ $rest
                continue
                ;;
            --)
                shift
                POSARGS+=("$@")
                ;;
            -[a-zA-Z]* | --[a-zA-Z]*)
                fatal "Unrecognized argument ${1:-}"
                ;;
            *)
                POSARGS+=("${1:-}")
                ;;
        esac
        shift
    done
}

parse_param() {
    local param arg
    local -i toshift=0

    if (($# == 0)); then
        return $toshift
    elif [[ "$1" =~ .*=.* ]]; then
        param="${1%%=*}"
        arg="${1#*=}"
    elif [[ "${2-}" =~ ^[^-].+ ]]; then
        param="$1"
        arg="$2"
        ((toshift++))
    fi

    if [[ -z "${arg-}" && ! "${OPTIONAL-}" ]]; then
        fatal "${param:-$1} requires an argument"
    fi

    echo "${arg:-}"
    return $toshift
}

quote() {
    echo \'"$@"\'
}

debug() {
    [ ! $DEBUG ] && return
    echo "$@" >&2
}

fatal() {
    echo $0: "$@" >&2
    exit 1
}

main "$@"
