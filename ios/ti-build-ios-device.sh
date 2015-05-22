#!/bin/bash
PATH_HERE=`pwd`
SHELL_TI=`which ti`
SHELL_NODE=`which node`

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

is_json ()
{
    if ${SHELL_NODE} -pe "JSON.parse(process.argv[1])" "$1" > /dev/null 2>&1; then
        return 0
    fi

    return 1
}

show_help ()
{
    me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
    echo "usage: ${me} [options]"
    echo "       -gdn=<value>, --get-device-name=<value>\tdisplay list device name"
    echo "       -dn=<value>, --device-name=<value>\tthe device name"
    echo "       -d=<value>, --dir=<value>\t\tthe directory titanium project"
}

for i in "$@"
do
case $i in
    -gdn=*|--get-device-name=*)
    ARG_GET_DEVICE_NAME="${i#*=}"
    shift
    ;;
    -dn=*|--device-name=*)
    ARG_DEVICE_NAME="${i#*=}"
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

hash ${SHELL_TI} > /dev/null 2>&1 || {
    echo "[FAIL] ti not installed"
    exit
}

hash ${SHELL_NODE} > /dev/null 2>&1 || {
    echo "[FAIL] node not installed"
    exit
}

if [[ "${ARG_DIR}" == "" && "${ARG_DEVICE_NAME}" == "" ]] || [[ "${ARG_DIR}" == "" && "${ARG_GET_DEVICE_NAME}" == "" ]]; then
    show_help
    exit
elif ! is_dir "${ARG_DIR}"; then
    echo "[FAIL] dir: ${ARG_DIR}"
    exit
elif [[ "${ARG_GET_DEVICE_NAME}" != "" ]]; then
    FILE_JSON="${ARG_DIR}/ti-config.json"

    if is_file "${ARG_DIR}/ti-config.json"; then
        CONTENT_JSON=$(cat "${FILE_JSON}")

        if is_json "${CONTENT_JSON}"; then
            CONTENT=$(${SHELL_NODE} -pe "var profiles = [];var json = JSON.parse(process.argv[1]).build.ios.device;for(var i in json){profiles.push(i)};process.stdout.write(profiles.join(' '));" "${CONTENT_JSON}")
            echo ${CONTENT:0:$((${#CONTENT} - 4))} | sed 's/ /|#|/g'
        fi
    fi

    exit
fi

FILE_JSON="${ARG_DIR}/ti-config.json"

if ! is_file "${ARG_DIR}/ti-config.json"; then
    echo "[FAIL] file: ${FILE_JSON}"
    exit
fi

CONTENT_JSON=$(cat "${FILE_JSON}")

if ! is_json "${CONTENT_JSON}"; then
    echo "[FAIL] the json file format invalid."
    exit
fi

DEVICEID=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.device.${ARG_DEVICE_NAME}.deviceid" "${CONTENT_JSON}")
if [[ "${DEVICEID}" == "undefined" ]]; then
    echo "[FAIL] the deviceid is undefined."
    exit
fi

DEVLOPERNAME=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.device.${ARG_DEVICE_NAME}.developername" "${CONTENT_JSON}")
if [[ "${DEVLOPERNAME}" == "undefined" ]]; then
    echo "[FAIL] the developername is undefined."
    exit
fi

PROFILEID=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.device.${ARG_DEVICE_NAME}.profileid" "${CONTENT_JSON}")
if [[ "${PROFILEID}" == "undefined" ]]; then
    echo "[FAIL] the profileid is undefined."
    exit
fi

JSMINIFY=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.device.${ARG_DEVICE_NAME}.jsminify" "${CONTENT_JSON}")
if [[ "${JSMINIFY}" == "undefined" ]]; then
    echo "[FAIL] the jsminify is undefined."
    exit
elif [[ "${JSMINIFY}" != "false" && "${JSMINIFY}" != "true" ]]; then
    echo "[FAIL] the jsminify is invalid. [false, true]"
    exit
fi

SDK=$(sed -n 's|\s*<sdk-version>\(.*\)</sdk-version>|\1|p' "${ARG_DIR}/tiapp.xml")
SDK=$(echo ${SDK} | sed 's/ //g')

if [[ "${SDK}" == "" ]]; then
    echo "[FAIL] the sdk is undefined."
    exit
fi

APPNAME=$(sed -n 's|\s*<name>\(.*\)</name>|\1|p' "${ARG_DIR}/tiapp.xml")
APPNAME=$(echo ${APPNAME} | sed 's/ //g')

if [[ "${JSMINIFY}" == "true" ]]; then
    ${SHELL_TI} build --project-dir "${ARG_DIR}" --platform "ios" --sdk "${SDK}" --device-id "${DEVICEID}" --developer-name "${DEVLOPERNAME}" --pp-uuid "${PROFILEID}" --target device --skip-js-minify
else
    ${SHELL_TI} build --project-dir "${ARG_DIR}" --platform "ios" --sdk "${SDK}" --device-id "${DEVICEID}" --developer-name "${DEVLOPERNAME}" --pp-uuid "${PROFILEID}" --target device
fi
