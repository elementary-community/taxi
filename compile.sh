valac $(find -name '*.vala' -printf '%p ') \
--target-glib=2.36 --pkg gtk+-3.0 --pkg granite --pkg posix --output app
./app
