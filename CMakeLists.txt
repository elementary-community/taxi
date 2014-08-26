# from http://elementaryos.org/docs/code/the-build-system
project (taxi)

cmake_minimum_required (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

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

find_package (PkgConfig)

pkg_check_modules (DEPS REQUIRED
    gtk+-3.0
    granite
    libsoup-2.4
)

add_definitions (${DEPS_CFLAGS})
add_definitions ("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)

include (ValaVersion)
ensure_vala_version("0.16" MINIMUM)

include (ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/config.vala
    src/Taxi.vala
    src/Protocol.vala
    src/ConflictFlag.vala
    src/Location.vala
    src/API/IConnectionSaver.vala
    src/API/IFileAccess.vala
    src/API/IFileOperations.vala
    src/API/IOperationInfo.vala
    src/Backend/ConnectionSaver.vala
    src/Backend/FileOperations.vala
    src/Backend/FileAccess.vala
    src/Backend/LocalFileAccess.vala
    src/Backend/OperationInfo.vala
    src/Backend/RemoteFileAccess.vala
    src/Frontend/GUI.vala
    src/Frontend/Widgets/ConnectBox.vala
    src/Frontend/Widgets/FilePane.vala
    src/Frontend/Widgets/OperationsPopover.vala
    src/Frontend/Widgets/PathBarSeparator.vala
    src/Frontend/Widgets/PathBar.vala
    src/Settings/SavedState.vala
    PACKAGES
        gtk+-3.0
        granite
        posix
        libsoup-2.4
        )

add_subdirectory (po)
add_subdirectory (data)

add_executable (${EXEC_NAME} ${VALA_C})
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/${APP_LAUNCHER} DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/taxi.svg DESTINATION ${DATADIR}/icons/hicolor/24x24/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/32/taxi.svg DESTINATION ${DATADIR}/icons/hicolor/32x32/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/48/taxi.svg DESTINATION ${DATADIR}/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/64/taxi.svg DESTINATION ${DATADIR}/icons/hicolor/64x64/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/128/taxi.svg DESTINATION ${DATADIR}/icons/hicolor/128x128/apps)
