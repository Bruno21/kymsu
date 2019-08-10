#!/usr/bin/env bash

KYMSU_PATH=`pwd`

# Make Kymsu accessible in PATH
ln -fs "${KYMSU_PATH}"/kymsu2.sh /usr/local/bin/kymsu2

# Store Kymsu stuff in home directory
mkdir -p ~/.kymsu && echo "${KYMSU_PATH}" > ~/.kymsu/path
cp -R "${KYMSU_PATH}/plugins.d" ~/.kymsu

echo "altKYMSU has been installed. Run kymsu2 command!"
echo "It's a fork from https://github.com/welcoMattic/kymsu"
echo "All credits to welcoMattic"
