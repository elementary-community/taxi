#!/bin/bash

while [ $# != 0 ]; do
    case $1 in
        --install)
            INSTALL=true
            ;;
        --adwaita)
            ARGS="-DADWAITA_FIXES=1"
            ;;
        --run)
            RUN_TAXI=true
            ;;
        *)
            ;;
    esac
    shift
done

rm -r build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr $ARGS .. || exit 1
make || exit 1

if [ $INSTALL ] ; then
    sudo make install || exit 1
fi

if [ $RUN_TAXI ] ; then
    if [ $INSTALL ]; then
        taxi
    else
        ./taxi
    fi
fi
