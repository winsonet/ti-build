#!/bin/bash
PATH_HERE=`pwd`
FONT_RED='\033[0;31m'
FONT_NO_COLOR='\033[0m'
SHELL_ADB=`which adb`

is_file ()
{
    if [ -f "$1" ] ; then
        return 0
    fi

    return 1
}

is_dir ()
{
    if [[ -d "$1" && ! -L "$1" ]] ; then
        return 0
    fi

    return 1
}

get_models ()
{
    echo $(${SHELL_ADB} devices -l)
}

show_help ()
{
    me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
    echo "usage: ${me} [options]"
    echo "       -gs=<value>, --get-sdk=<value>\t\tdisplay list sdk version"
    echo "       -s=<value>, --sdk=<value>\t\tthe sdk version [$(echo $(get_sdks) | sed 's/|#|/, /g')]"
    echo "       -gdn=<value>, --get-device-name=<value>\tdisplay list device name"
    echo "       -dn=<value>, --device-name=<value>\tthe device name"
    echo "       -gdi=<value>, --get-device-id=<value>\tdisplay list device id"
    echo "       -di=<value>, --device-id=<value>\t\tthe device id"
    echo "       -d=<value>, --dir=<value>\t\tthe directory titanium project"
}

echo $(get_models)
