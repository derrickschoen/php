#!/bin/bash

retcode=0
ping_url="https://api.rosette.com/rest/v1"
errors=( "Exception" "processingFailure" "badRequest" "ParseError" "ValueError" "SyntaxError" "AttributeError" "ImportError" )

#------------------ Functions ----------------------------------------------------

#Gets called when the user doesn't provide any args
function HELP {
    echo -e "\nusage: source_file.php --key API_KEY [--url ALT_URL]"
    echo "  API_KEY       - Rosette API key (required)"
    echo "  FILENAME      - PHP source file (optional)"
    echo "  ALT_URL       - Alternate service URL (optional)"
    echo "Compiles and runs the source file(s) using the local development source."
    exit 1
}

if [ ! -z ${ALT_URL} ]; then
    ping_url=${ALT_URL}
fi

#Checks if Rosette API key is valid
function checkAPI {
    match=$(curl "${ping_url}/ping" -H "X-RosetteAPI-Key: ${API_KEY}" |  grep -o "forbidden")
    if [ ! -z $match ]; then
        echo -e "\nInvalid Rosette API Key"
        exit 1
    fi  
}

function cleanURL() {
    # strip the trailing slash off of the alt_url if necessary
    if [ ! -z "${ALT_URL}" ]; then
        case ${ALT_URL} in
            */) ALT_URL=${ALT_URL::-1}
                echo "Slash detected"
                ;;
        esac
        ping_url=${ALT_URL}
    fi
    echo "Calling URL: ${ping_url}"
}

function validateURL() {
    match=$(curl "${ping_url}/ping" -H "X-RosetteAPI-Key: ${API_KEY}" |  grep -o "Rosette API")
    if [ "${match}" = "" ]; then
        echo -e "\n${ping_url} server not responding\n"
        exit 1
    fi  
}

function runExample() {
    echo -e "\n---------- ${1} start -------------"
    result=""
    if [ -z ${ALT_URL} ]; then
        result="$(php ${1} --key ${API_KEY} 2>&1 )"
    else
        result="$(php ${1} --key ${API_KEY} --url=${ALT_URL} 2>&1 )"
    fi
    echo "${result}"
    echo -e "\n---------- ${1} end -------------"
    for err in "${errors[@]}"; do 
        if [[ ${result} == *"${err}"* ]]; then
            retcode=1
        fi
    done
}
#------------------ Functions End ------------------------------------------------

#Gets API_KEY, FILENAME, ALT_URL, GIT_USERNAME and VERSION if present
while getopts ":API_KEY:FILENAME:ALT_URL" arg; do
    case "${arg}" in
        API_KEY)
            API_KEY=${OPTARG}
            usage
            ;;
        ALT_URL)
            ALT_URL=${OPTARG}
            usage
            ;;
        FILENAME)
            FILENAME=${OPTARG}
            usage
            ;;
    esac
done

cleanURL

validateURL

#Copy the mounted content in /source to current WORKDIR
cp -r -n /source/* .
cp -r vendor /php-dev/examples

#Run the examples
if [ ! -z ${API_KEY} ]; then
    checkAPI
    cd /php-dev/examples
    if [ ! -z ${FILENAME} ]; then
        echo -e "\nRunning example against: ${ping_url}\n"
        runExample ${FILENAME}
    else
        echo -e "\nRunning examples against: ${ping_url}\n"
        for file in *.php; do
            runExample ${file}
        done
    fi
else 
    HELP
fi


#Run unit tests
cd /php-dev && ./bin/phpspec run --config=phpspec.yml --bootstrap=./vendor/autoload.php --no-interaction --format=pretty

#Run php-cs-fixer
./bin/php-cs-fixer fix . --dry-run --diff --level=psr2

exit ${retcode}
