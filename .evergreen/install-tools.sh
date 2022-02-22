#!/bin/bash
set -o xtrace   # Write all commands first to stderr
set -o errexit  # Exit the script with error if any of the commands fail

# Script for installing various tool dependencies.

# variables
PROJECT_DIRECTORY=${PROJECT_DIRECTORY:-"MISSING_PROJECT_DIRECTORY"}
SWIFT_VERSION=${SWIFT_VERSION:-"MISSING_SWIFT_VERSION"}
INSTALL_DIR="${PROJECT_DIRECTORY}/opt"

export SWIFTENV_ROOT="${INSTALL_DIR}/swiftenv"
export PATH="${SWIFTENV_ROOT}/bin:$PATH"

# usage: build_from_gh [name] [url] [tag]
build_from_gh () {
    NAME=$1
    URL=$2
    TAG=$3

    git clone ${URL} --depth 1 --branch ${TAG} ${INSTALL_DIR}/${NAME}
    cd ${INSTALL_DIR}/${NAME}
    swift build -c release
    cd -
}

# usage: install_from_gh [name] [url]
install_from_gh () {
    NAME=$1
    URL=$2
    mkdir ${INSTALL_DIR}/${NAME}
    curl -L ${URL} -o ${INSTALL_DIR}/${NAME}/${NAME}.zip
    unzip ${INSTALL_DIR}/${NAME}/${NAME}.zip -d ${INSTALL_DIR}/${NAME}
}

# enable swiftenv
eval "$(swiftenv init -)"
swiftenv local $SWIFT_VERSION

if [ $1 == "swiftlint" ]
then
    build_from_gh swiftlint https://github.com/realm/SwiftLint "0.46.2"
elif [ $1 == "swiftformat" ]
then
    build_from_gh swiftformat https://github.com/nicklockwood/SwiftFormat "0.49.4"
else
    echo Missing/unknown install option: "$1"
fi
