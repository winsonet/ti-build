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

generate_keypair ()
{
    KEYSTORE=""
    KEYPASS=""
    ALIAS=""
    VALIDITY=""

    keytool -genkeypair -v -keystore android.keystore -alias helloworld -keyalg RSA -sigalg SHA1withRSA -validity 10000
}

get_keystore ()
{
    echo "get keystore"
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

