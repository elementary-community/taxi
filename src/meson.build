conf_data = configuration_data()
conf_data.set('PROJECT_NAME', meson.project_name())
conf_data.set('EXEC_NAME', meson.project_name())
conf_data.set('DATADIR', get_option('datadir'))
conf_data.set('PKGDATADIR', get_option('datadir') + '/' + meson.project_name())
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('RELEASE_NAME', 'Taxi')
conf_data.set('VERSION', '1.0.0')
conf_data.set('VERSION_INFO', 'The FTP Client that drives you anywhere')
conf_data.set('PREFIX', get_option('prefix'))

config_header = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

executable(
    meson.project_name(),
    'Application.vala',
    'Enum/Protocol.vala',
    'Enum/ConflictFlag.vala',
    'Enum/Location.vala',
    'API/IConnectionSaver.vala',
    'API/IFileAccess.vala',
    'API/IFileOperations.vala',
    'API/IOperationInfo.vala',
    'Backend/ConnectionSaver.vala',
    'Backend/FileOperations.vala',
    'Backend/FileAccess.vala',
    'Backend/LocalFileAccess.vala',
    'Backend/OperationInfo.vala',
    'Backend/RemoteFileAccess.vala',
    'Frontend/MainWindow.vala',
    'Frontend/Widgets/ConnectBox.vala',
    'Frontend/Widgets/FilePane.vala',
    'Frontend/Widgets/OperationsPopover.vala',
    'Frontend/Widgets/PathBarSeparator.vala',
    'Frontend/Widgets/PathBar.vala',
    asresources,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=0.5'),
        dependency('gtk+-3.0', version: '>=3.22'),
        dependency('libsoup-2.4'),
        meson.get_compiler('vala').find_library('posix', required : false)
    ],
    install : true
)

vala_lint = find_program('io.elementary.vala-lint', required : false)
if vala_lint.found()
    test (
        'Vala lint',
        vala_lint,
        args: ['-d', join_paths(meson.source_root(), 'src')]
    )
endif