#!/bin/bash
PATH_HERE=`pwd`
SHELL_TI=`which ti`
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

get_models_and_device_ids ()
{
    DEVICE_IDS=$(echo $(${SHELL_ADB} devices -l | grep 'usb' | awk '{print $1}'))
    IFS=' ' read -a DEVICE_IDS <<< "${DEVICE_IDS}"
    
    for DEVICE_ID in "${DEVICE_IDS[@]}"
    do
        if [[ "${DEVICE_ID}" != "" ]]; then
            MODEL=$(${SHELL_ADB} -s ${DEVICE_ID} shell getprop ro.product.model)
            MODEL=$(echo ${MODEL:0:(${#MODEL}-1)})
            MODEL_AND_DEVICE_ID+=("${MODEL}:${DEVICE_ID}")
        fi
    done

    MODEL_AND_DEVICE_ID=$(echo "${MODEL_AND_DEVICE_ID[@]}" | sed 's/ /|#|/g')
    echo "${MODEL_AND_DEVICE_ID}"
}

get_device_ids ()
{
    DEVICE_IDS=()
    MODEL_AND_DEVICE_ID=$(get_models_and_device_ids)
    IFS='|#|' read -a MODEL_AND_DEVICE_ID <<< "${MODEL_AND_DEVICE_ID}"

    for ITEM in "${MODEL_AND_DEVICE_ID[@]}"
    do
        if [[ "${ITEM}" != "" ]]; then
            ITEM=$(echo ${ITEM} | awk -F':' '{print $2}')
            DEVICE_IDS+=("${ITEM}")
        fi
    done

    DEVICE_IDS=$(echo "${DEVICE_IDS[@]}" | sed 's/ /|#|/g')
    echo "${DEVICE_IDS}"
}

get_device_id_with_model ()
{
    DEVICE_ID=""
    MODEL_AND_DEVICE_ID=$(get_models_and_device_ids)
    IFS='|#|' read -a MODEL_AND_DEVICE_ID <<< "${MODEL_AND_DEVICE_ID}"

    for ITEM in "${MODEL_AND_DEVICE_ID[@]}"
    do
        if [[ "${ITEM}" != "" ]]; then
            MODEL=$(echo ${ITEM} | awk -F':' '{print $1}')
            if [[ "${MODEL}" != "" && "${MODEL}" == "$1" ]]; then
                DEVICE_ID=$(echo ${ITEM} | awk -F':' '{print $2}')
            fi
        fi
    done

    echo "${DEVICE_ID}"
}

get_models () 
{
    MODELS=()
    MODEL_AND_DEVICE_ID=$(get_models_and_device_ids)
    IFS='|#|' read -a MODEL_AND_DEVICE_ID <<< "${MODEL_AND_DEVICE_ID}"

    for ITEM in "${MODEL_AND_DEVICE_ID[@]}"
    do
        if [[ "${ITEM}" != "" ]]; then
            ITEM=$(echo ${ITEM} | awk -F':' '{print $1}')
            MODELS+=("${ITEM}")
        fi
    done

    MODELS=$(echo "${MODELS[@]}" | sed 's/ /|#|/g')
    echo "${MODELS}"
}

get_model_with_device_id ()
{
    MODEL=""
    MODEL_AND_DEVICE_ID=$(get_models_and_device_ids)
    IFS='|#|' read -a MODEL_AND_DEVICE_ID <<< "${MODEL_AND_DEVICE_ID}"

    for ITEM in "${MODEL_AND_DEVICE_ID[@]}"
    do
        if [[ "${ITEM}" != "" ]]; then
            DEVICE_ID=$(echo ${ITEM} | awk -F':' '{print $2}')
            if [[ "${DEVICE_ID}" != "" && "${DEVICE_ID}" == "$1" ]]; then
                MODEL=$(echo ${ITEM} | awk -F':' '{print $1}')
            fi
        fi
    done

    echo "${MODEL}"
}

show_help ()
{
    me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
    echo "usage: ${me} [options]"
    echo "       -di=<value>, --device-id=<value>\t\t\t\tdisplay list device id"
    echo "       -gm=<value>, --get-model=<value>\t\t\t\tthe device model"
    echo "       -gdiwm=<value>, --get-device-id-with-model=<value>\tdisplay get device id with model"
    echo "       -gmwdi=<value>, ---get-model-with-device-id=<value>\tdisplay get model with device id"
    echo "       -d=<value>, --dir=<value>\t\t\t\tthe directory titanium project"
}

hash ${SHELL_TI} > /dev/null 2>&1 || {
    echo "[FAIL] ti not installed"
    exit
}

hash ${SHELL_ADB} > /dev/null 2>&1 || {
    echo "[FAIL] adb not installed"
    exit
}

for i in "$@"
do
case $i in
    -gdi=*|--get-device-id=*)
    ARG_GET_DEVICE_ID="${i#*=}"
    shift
    ;;
    -gdiwm=*|--get-device-id-with-model=*)
    ARG_GET_DEVICE_ID_WITH_MODEL="${i#*=}"
    shift
    ;;
    -di=*|--device-id=*)
    ARG_DEVICE_ID="${i#*=}"
    shift
    ;;
    -gm=*|--get-model=*)
    ARG_GET_MODEL="${i#*=}"
    shift
    ;;
    -gmwdi=*|--get-model-with-device-id=*)
    ARG_GET_MODEL_WITH_DEVICE_ID="${i#*=}"
    shift
    ;;
    -d=*|--dir=*)
    ARG_DIR="${i#*=}"
    shift
    ;;
    *)
        show_help
        exit
    ;;
esac
done

if [[ "${ARG_GET_DEVICE_ID}" != "" ]]; then
    get_device_ids
    exit
elif [[ "${ARG_GET_DEVICE_ID_WITH_MODEL}" != "" ]]; then
    get_device_id_with_model "${ARG_GET_DEVICE_ID_WITH_MODEL}"
    exit
elif [[ "${ARG_GET_MODEL}" != "" ]]; then
    get_models
    exit
elif [[ "${ARG_GET_MODEL_WITH_DEVICE_ID}" != "" ]]; then
    get_model_with_device_id "${ARG_GET_MODEL_WITH_DEVICE_ID}"
    exit
fi

${SHELL_TI} build --project-dir "${ARG_DIR}" --log-level debug --platform android --device-id "${ARG_DEVICE_ID}" --target device --skip-js-minify

