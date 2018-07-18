project('com.github.Alecaddd.taxi', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

executable(
    meson.project_name(),
    'src/Taxi.vala',
    'src/Enum/Protocol.vala',
    'src/Enum/ConflictFlag.vala',
    'src/Enum/Location.vala',
    'src/API/IConnectionSaver.vala',
    'src/API/IFileAccess.vala',
    'src/API/IFileOperations.vala',
    'src/API/IOperationInfo.vala',
    'src/Backend/ConnectionSaver.vala',
    'src/Backend/FileOperations.vala',
    'src/Backend/FileAccess.vala',
    'src/Backend/LocalFileAccess.vala',
    'src/Backend/OperationInfo.vala',
    'src/Backend/RemoteFileAccess.vala',
    'src/Frontend/GUI.vala',
    'src/Frontend/Widgets/ConnectBox.vala',
    'src/Frontend/Widgets/FilePane.vala',
    'src/Frontend/Widgets/OperationsPopover.vala',
    'src/Frontend/Widgets/PathBarSeparator.vala',
    'src/Frontend/Widgets/PathBar.vala',
    'src/Settings/SavedState.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite', version: '>=0.5'),
        dependency('gtk+-3.0'),
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

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')

