#!/bin/bash
PATH_HERE=`pwd`
SHELL_TI=`which ti`
SHELL_XCRUN=`which xcrun`

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

get_sdks ()
{
    echo $(${SHELL_XCRUN} simctl list | grep '(com.apple.CoreSimulator.SimRuntime.iOS-[0-9]-[0-9])' | grep -v '(unavailable, runtime path not found)' | awk '{print $3}' | sed 's/(//g') | sed 's/ /|#|/g'
}

is_sdk () 
{
    SDKS=$(get_sdks)

    if [[ "$1" != "" && ":${SDKS}:" == *"$1"* ]]; then
        return 0
    fi

    return 1
}

get_device_name ()
{
    VERSION=$(${SHELL_XCRUN} simctl list | grep '(com.apple.CoreSimulator.SimRuntime.iOS-[0-9]-[0-9])' | grep "($1 - " | grep -v '(unavailable, runtime path not found)' | awk '{print $2}')

    CONTENT=$(${SHELL_XCRUN} simctl list)
    CONTENT=$(echo ${CONTENT} --)
    CONTENT=$(echo ${CONTENT} | egrep -o "\\-\\- iOS ${VERSION} \\-\\- (.*?) \\-\\-")
    CONTENT=$(echo ${CONTENT} | sed "s/-- iOS ${VERSION} -- //g" | sed 's/ --//g' | sed 's/(Shutdown)/,/g' | sed 's/(Booted)/,/g' | sed 's/ , /,/g' | sed 's/ ,//g' | sed 's/ ([0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{12\})//g')
    CONTENT=$(echo ${CONTENT} | sed 's/,/|#|/g')
    echo "${CONTENT}"
}

is_device_name () 
{
    DEVICE_NAME=$(get_device_name $1)

    if [[ "$1" != "" && "$2" != "" && ":${DEVICE_NAME}:" == *"$2"* ]]; then
        return 0
    fi

    return 1
}

get_device_id ()
{
    VERSION=$(${SHELL_XCRUN} simctl list | grep '(com.apple.CoreSimulator.SimRuntime.iOS-[0-9]-[0-9])' | grep "($1 - " | grep -v '(unavailable, runtime path not found)' | awk '{print $2}')

    CONTENT=$(${SHELL_XCRUN} simctl list)
    CONTENT=$(echo ${CONTENT} --)
    CONTENT=$(echo ${CONTENT} | egrep -o "\\-\\- iOS ${VERSION} \\-\\- (.*?) \\-\\-")
    CONTENT=$(echo ${CONTENT} | sed "s/-- iOS ${VERSION} -- //g" | sed 's/ --//g' | sed 's/(Shutdown)/,/g' | sed 's/(Booted)/,/g' | sed 's/ , /,/g' | sed 's/ ,//g' | grep -o "$2 ([0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{12\})")
    CONTENT=$(echo ${CONTENT} | grep -o '[0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{12\}')
    echo "${CONTENT}"
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

for i in "$@"
do
case $i in
    -gs=*|--get-sdk=*)
    ARG_GET_SDK="${i#*=}"
    shift
    ;;
    -s=*|--sdk=*)
    ARG_SDK="${i#*=}"
    shift
    ;;
    -gdn=*|--get-device-name=*)
    ARG_GET_DEVICE_NAME="${i#*=}"
    shift
    ;;
    -dn=*|--device-name=*)
    ARG_DEVICE_NAME="${i#*=}"
    shift
    ;;
    -gdi=*|--get-device-id=*)
    ARG_GET_DEVICE_ID="${i#*=}"
    shift
    ;;
    -i=*|--device-id=*)
    ARG_DEVICE_ID="${i#*=}"
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

hash ${SHELL_XCRUN} > /dev/null 2>&1 || {
    echo "[FAIL] xcrun not installed"
    exit
}

if [[ "${ARG_GET_SDK}" != "" ]]; then
    echo $(get_sdks)
    exit
elif is_sdk "${ARG_SDK}" && [[ "${ARG_GET_DEVICE_NAME}" != "" ]]; then
    echo $(get_device_name "${ARG_SDK}")
    exit
elif is_sdk "${ARG_SDK}" && is_device_name "${ARG_SDK}" "${ARG_DEVICE_NAME}"; then
    echo $(get_device_id "${ARG_SDK}" "${ARG_DEVICE_NAME}")
    exit
elif ! is_dir "${ARG_DIR}"; then
    echo "[FAIL] dir: ${ARG_DIR}"
    exit
fi

SDK=$(sed -n 's|\s*<sdk-version>\(.*\)</sdk-version>|\1|p' "${ARG_DIR}/tiapp.xml")
SDK=$(echo ${SDK} | sed 's/ //g')

if [[ "${SDK}" == "" ]]; then
    echo "[FAIL] the sdk is undefined."
    exit
fi

${SHELL_TI} build --project-dir "${ARG_DIR}" --platform "ios" --sdk "${SDK}"  --sim-version "${ARG_SDK}" --device-id "${ARG_DEVICE_ID}"
