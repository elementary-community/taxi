rm -r build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
while test $# -eq 1; do
    case "$1" in
        --install)
            sudo make install
            cd ..
            break
            ;;
        *)
            break
            ;;
    esac
done
