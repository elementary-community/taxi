# from http://elementaryos.org/docs/code/the-build-system
# project name
project (taxi)
# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.6)
# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PROGRAM_NAME "Taxi")
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (EXEC_NAME ${CMAKE_PROJECT_NAME})
set (RELEASE_NAME "Crown Vic")
set (VERSION "0.1")
set (VERSION_INFO "Initial release of Taxi.")
set (APP_LAUNCHER "taxi.desktop")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)
# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED
    gtk+-3.0
    granite
    libsoup-2.4
)
add_definitions(${DEPS_CFLAGS})
add_definitions("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})
# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)
# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Taxi.vala
    src/ConnectionSaver.vala
    src/ConnInfo.vala
    src/FileOperations.vala
    src/GUI.vala
    src/FileAccess.vala
    src/LocalFileAccess.vala
    src/RemoteFileAccess.vala
    src/Widgets/ConnectBox.vala
    src/Widgets/FilePane.vala
    src/Widgets/PathBar.vala
    src/API/IConnectionSaver.vala
    src/API/IConnInfo.vala
    src/API/IFileAccess.vala
    src/API/IFileOperations.vala
    src/config.vala
# tell what libraries to use when compiling
    PACKAGES
        gtk+-3.0
        granite
        posix
        libsoup-2.4
        )
# translations
add_subdirectory(po)
# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/${APP_LAUNCHER} DESTINATION ${DATADIR}/applications/)
