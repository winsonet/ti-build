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

get_device_id ()
{
    MODEL=$1
    DEVICE_IDS=$(get_device_ids)
    ID=""

    IFS='|#|' read -a DEVICE_IDS <<< "${DEVICE_IDS}"

    # echo ${DEVICE_IDS[@]}

    for DEVICE_ID in "${DEVICE_IDS[@]}"
    do
        if [[ "${DEVICE_ID}" != "" ]]; then
            # echo "${DEVICE_ID}"
            DEVICE_MODEL=$(${SHELL_ADB} -s ${DEVICE_ID} shell getprop ro.product.model)
            DEVICE_MODEL=$(echo ${DEVICE_MODEL:0:(${#DEVICE_MODEL}-1)})
            # echo "${DEVICE_MODEL}"
            echo "${MODEL} -> ${DEVICE_MODEL}"
            if [[ "${MODEL}" == "${DEVICE_MODEL}" ]]; then
                ID=$(${SHELL_ADB} -s ${DEVICE_ID} shell getprop ro.serialno)
            fi
        fi
    done

    echo "${ID}"
}

get_device_ids ()
{
    # get device id is text string type one line.
    echo $(${SHELL_ADB} devices -l | grep 'usb' | awk '{print $1}') | sed 's/ /|#|/g'
}

get_models ()
{
    MODELS=()
    DEVICE_IDS=$(get_device_ids)

    # get device id from get_device_id function and convert text to array.
    IFS='|#|' read -a DEVICE_IDS <<< "${DEVICE_IDS}"
    
    for DEVICE_ID in "${DEVICE_IDS[@]}"
    do
        if [[ "${DEVICE_ID}" != "" ]]; then
            MODEL=$(${SHELL_ADB} -s ${DEVICE_ID} shell getprop ro.product.model)

            MODEL=$(echo ${MODEL:0:(${#MODEL}-1)})
            MODELS+=("${MODEL}")
        fi
    done

    MODELS=$(echo "${MODELS[@]}" | sed 's/ /|#|/g')

    echo "${MODELS}"
}

show_help ()
{
    me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
    echo "usage: ${me} [options]"
    echo "       -gs=<value>, --get-model=<value>\t\tdisplay list sdk version"
    echo "       -s=<value>, --sdk=<value>\t\tthe sdk version [$(echo $(get_sdks) | sed 's/|#|/, /g')]"
    echo "       -gdn=<value>, --get-device-name=<value>\tdisplay list device name"
    echo "       -dn=<value>, --device-name=<value>\tthe device name"
    echo "       -gdi=<value>, --get-device-id=<value>\tdisplay list device id"
    echo "       -di=<value>, --device-id=<value>\t\tthe device id"
    echo "       -d=<value>, --dir=<value>\t\tthe directory titanium project"
}

hash ${SHELL_ADB} > /dev/null 2>&1 || {
    echo "[${FONT_RED}FAIL${FONT_NO_COLOR}] adb not installed"
    exit
}

# get_models

# get_device_id "D2302"

# $(get_device_id "GT-I9300T" "GT-I9300T")

for i in "$@"
do
case $i in
    -gs=*|--get-model=*)
    ARG_GET_MODEL="${i#*=}"
    shift
    ;;
    -di=*|--device-id=*)
    ARG_GET_ID="${i#*=}"
    shift
    ;;
    *)
        show_help
        exit
    ;;
esac
done

if [[ "${ARG_GET_MODEL}" != "" ]]; then
    echo $(get_models)
    exit
elif [[ "${ARG_GET_ID}" != "" ]]; then
    echo $(get_device_id ${ARG_GET_ID})
    exit
fi

