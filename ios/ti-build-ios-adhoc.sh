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

plist_templete ()
{
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>{IPAURL}</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>full-size-image</string>
                    <key>needs-shine</key>
                    <false/>
                    <key>url</key>
                    <string>{APPICON512x512}</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>display-image</string>
                    <key>needs-shine</key>
                    <false/>
                    <key>url</key>
                    <string>{APPICON57x57}</string>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>{APPID}</string>
                <key>bundle-version</key>
                <string>{APPVERSION}</string>
                <key>kind</key>
                <string>software</string>
                <key>title</key>
                <string>{APPNAME}</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>"
}

get_device_family ()
{
    echo "iphone|#|ipad|#|universal"
}

is_device_family () 
{
    device_family=$(get_device_family)

    if [[ "$1" != "" && ":${device_family}:" == *"$1"* ]]; then
        return 0
    fi

    return 1
}

timestamp ()
{
    echo `date +%Y%m%d%H%M%S`
}

show_help ()
{
    me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
    echo "usage: ${me} [options]"
    echo "       -gpn=<value>, --get-profile-name=<value>\tdisplay list profile name"
    echo "       -pn=<value>, --profile-name=<value>\tthe profile name"
    echo "       -d=<value>, --dir=<value>\t\tthe directory titanium project"
}

for i in "$@"
do
case $i in
    -gpn=*|--get-profile-name=*)
    ARG_GET_PROFILE_NAME="${i#*=}"
    shift
    ;;
    -pn=*|--profile-name=*)
    ARG_PROFILE_NAME="${i#*=}"
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

if [[ "${ARG_DIR}" == "" && "${ARG_PROFILE_NAME}" == "" ]] || [[ "${ARG_DIR}" == "" && "${ARG_GET_PROFILE_NAME}" == "" ]]; then
    show_help
    exit
elif ! is_dir "${ARG_DIR}"; then
    echo "[FAIL] dir: ${ARG_DIR}"
    exit
elif [[ "${ARG_GET_PROFILE_NAME}" != "" ]]; then
    FILE_JSON="${ARG_DIR}/ti-config.json"

    if is_file "${ARG_DIR}/ti-config.json"; then
        CONTENT_JSON=$(cat "${FILE_JSON}")

        if is_json "${CONTENT_JSON}"; then
            CONTENT=$(${SHELL_NODE} -pe "var profiles = [];var json = JSON.parse(process.argv[1]).build.ios.adhoc;for(var i in json){profiles.push(i)};process.stdout.write(profiles.join(' '));" "${CONTENT_JSON}")
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

DEVICEFAMILY=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.devicefamily" "${CONTENT_JSON}")
if [[ "${DEVICEFAMILY}" == "undefined" ]]; then
    echo "[FAIL] the devicefamily is undefined."
    exit
elif ! is_device_family "${DEVICEFAMILY}"; then
    echo "[FAIL] the devicefamily is invalid. [$(echo $(get_device_family) | sed 's/ /, /g')]"
    exit
fi

DISTRIBUTIONNAME=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.distributionname" "${CONTENT_JSON}")
if [[ "${DISTRIBUTIONNAME}" == "undefined" ]]; then
    echo "[FAIL] the distributionname is undefined."
    exit
fi

PROFILEID=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.profileid" "${CONTENT_JSON}")
if [[ "${PROFILEID}" == "undefined" ]]; then
    echo "[FAIL] the profileid is undefined."
    exit
fi

IPAURL=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.ipaurl" "${CONTENT_JSON}")
if [[ "${IPAURL}" == "undefined" ]]; then
    echo "[FAIL] the ipaurl is undefined."
    exit
fi

OUTPUTDIR=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.outputdir" "${CONTENT_JSON}")

if [[ "${OUTPUTDIR}" == "undefined" ]]; then
    echo "[FAIL] the outputdir is undefined."
    exit
else
    OUTPUTDIR=${OUTPUTDIR/\$\{HOME\}/$HOME}
    if ! is_dir "${OUTPUTDIR}"; then
        echo "[FAIL] output dir: ${OUTPUTDIR}"
        exit
    fi
fi

JSMINIFY=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.jsminify" "${CONTENT_JSON}")
if [[ "${JSMINIFY}" == "undefined" ]]; then
    echo "[FAIL] the jsminify is undefined."
    exit
elif [[ "${JSMINIFY}" != "false" && "${JSMINIFY}" != "true" ]]; then
    echo "[FAIL] the jsminify is invalid. [false, true]"
    exit
fi

PLIST=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.plist" "${CONTENT_JSON}")
if [[ "${PLIST}" == "undefined" ]]; then
    echo "[FAIL] the plist is undefined."
    exit
elif [[ "${PLIST}" != "false" && "${PLIST}" != "true" ]]; then
    echo "[FAIL] the plist is invalid. [false, true]"
    exit
fi

APPICON=$(${SHELL_NODE} -pe "JSON.parse(process.argv[1]).build.ios.adhoc.${ARG_PROFILE_NAME}.appicon" "${CONTENT_JSON}")
if [[ "${APPICON}" == "undefined" ]]; then
    echo "[FAIL] the appicon is undefined."
    exit
elif [[ "${APPICON}" != "false" && "${APPICON}" != "true" ]]; then
    echo "[FAIL] the appicon is invalid. [false, true]"
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

OUTPUTDIR="${OUTPUTDIR}/${APPNAME}"
mkdir -p ${OUTPUTDIR}

TIMESTAMP=$(timestamp)

if [[ "${PLIST}" == "true" ]]; then
    APPID=$(sed -n 's|\s*<id>\(.*\)</id>|\1|p' "${ARG_DIR}/tiapp.xml")
    APPID=$(echo ${APPID} | sed 's/ //g')

    APPVERSION=$(sed -n 's|\s*<version>\(.*\)</version>|\1|p' "${ARG_DIR}/tiapp.xml")
    APPVERSION=$(echo ${APPVERSION} | sed 's/ //g')

    CONTENT_PLIST=$(plist_templete)
    CONTENT_PLIST=$(echo ${CONTENT_PLIST} | sed "s/{IPAURL}/${IPAURL}/g")
    CONTENT_PLIST=$(echo ${CONTENT_PLIST} | sed "s/{APPID}/${APPID}/g")
    CONTENT_PLIST=$(echo ${CONTENT_PLIST} | sed "s/{APPVERSION}/${APPVERSION}/g")
    CONTENT_PLIST=$(echo ${CONTENT_PLIST} | sed "s/{APPNAME}/${APPNAME}/g")

    echo ${CONTENT_PLIST} > "${OUTPUTDIR}/${TIMESTAMP}-${APPNAME}.plist"
fi

if [[ "${APPICON}" == "true" ]]; then
    APPICON_FILE="${ARG_DIR}/Resources/iphone/iTunesArtwork@2x"

    if is_file "${APPICON_FILE}"; then
        cp "${APPICON_FILE}" "${OUTPUTDIR}/${TIMESTAMP}-${APPNAME}.png"
    fi
fi

if [[ "${JSMINIFY}" == "true" ]]; then
    ${SHELL_TI} build --project-dir "${ARG_DIR}" --platform "ios" --sdk "${SDK}" --device-family "${DEVICEFAMILY}" --tall --retina --distribution-name "${DISTRIBUTIONNAME}" --pp-uuid "${PROFILEID}" --target dist-adhoc --output-dir "${OUTPUTDIR}"  --skip-js-minify
else
    ${SHELL_TI} build --project-dir "${ARG_DIR}" --platform "ios" --sdk "${SDK}" --device-family "${DEVICEFAMILY}" --tall --retina --distribution-name "${DISTRIBUTIONNAME}" --pp-uuid "${PROFILEID}" --target dist-adhoc --output-dir "${OUTPUTDIR}"
fi

if is_file "${OUTPUTDIR}/${APPNAME}.ipa"; then
    mv "${OUTPUTDIR}/${APPNAME}.ipa" "${OUTPUTDIR}/${TIMESTAMP}-${APPNAME}.ipa"
fi
