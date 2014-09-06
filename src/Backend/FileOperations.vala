/***
  Copyright (C) 2014 Kiran John Hampal <kiran@elementaryos.org>

  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see <http://www.gnu.org/licenses>
***/

namespace Taxi {

    class FileOperations : IFileOperations, Object {

        public async bool delete_recursive (
            File file,
            Cancellable? cancellable = null
        ) throws Error {
            var operation = new OperationInfo (file, cancellable);
            operation_added (operation);
            try {
                return yield delete_recursive_helper (file, cancellable);
            } catch (Error e) {
                throw e;
            } finally {
                operation_removed (operation);
            }
        }

        public async bool delete_recursive_helper (
            File file,
            Cancellable? cancellable = null
        ) throws Error {
            var file_type = file.query_file_type (
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                cancellable
            );
            if (file_type == FileType.DIRECTORY) {
                string file_path = file.get_path ();
                var file_list = yield get_file_list (file);
                foreach (FileInfo file_info in file_list) {
                    yield delete_recursive_helper (
                        File.new_for_path (Path.build_filename (
                            file_path,
                            file_info.get_name ()
                        )),
                        cancellable
                    );
                }
            }
            return yield file.delete_async (Priority.DEFAULT, cancellable);
        }

        public async List<FileInfo> get_file_list (File file) throws Error {
            var file_enum = yield file.enumerate_children_async (
                "*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                Priority.DEFAULT,
                null
            );
            return yield file_enum.next_files_async (int.MAX, Priority.DEFAULT);
        }

        public async void copy_recursive (
            File source,
            File destination,
            FileCopyFlags flags = FileCopyFlags.NONE,
            Cancellable? cancellable = null
        ) throws Error {
            var operation = new OperationInfo (source, cancellable);
            operation_added (operation);
            try {
                yield copy_recursive_helper (
                    source,
                    destination,
                    &flags,
                    cancellable
                );
            } catch (Error e) {
                warning (e.message);
                throw e;
            } finally {
                operation_removed (operation);
            }
        }

        private async void copy_recursive_helper (
            File source,
            File destination,
            FileCopyFlags* flags,
            Cancellable? cancellable = null
        ) throws Error {
            var file_type = source.query_file_type (
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                cancellable
            );
            if (file_type == FileType.DIRECTORY) {
                if (!destination.query_exists ()) {
                    yield destination.make_directory_async (Priority.DEFAULT, cancellable);
                    source.copy_attributes (destination, *flags, cancellable);
                }
                string source_path = source.get_path ();
                string destination_path = destination.get_path ();
                var file_list = yield get_file_list (source);
                foreach (FileInfo file_info in file_list) {
                    yield copy_recursive_helper (
                        File.new_for_path (Path.build_filename (
                            source_path,
                            file_info.get_name ()
                        )),
                        File.new_for_path (Path.build_filename (
                            destination_path,
                            file_info.get_name ()
                        )),
                        flags,
                        cancellable
                    );
                }
            } else if (file_type == FileType.REGULAR) {
                var tmp_flag = *flags;
                if (*flags == FileCopyFlags.NONE && destination.query_exists ()) {
                    switch ((ConflictFlag)ask_overwrite (destination)) {
                        case ConflictFlag.REPLACE_ALL:
                            *flags = FileCopyFlags.OVERWRITE;
                            tmp_flag = *flags;
                            break;
                        case ConflictFlag.REPLACE:
                            tmp_flag = FileCopyFlags.OVERWRITE;
                            break;
                        case ConflictFlag.SKIP:
                        default:
                            return;
                    }
                }
                yield source.copy_async (
                    destination,
                    tmp_flag,
                    Priority.DEFAULT,
                    cancellable
                );
            } else {
                warning ("Unrecognised file type" + file_type.to_string ());
            }
        }

        public async bool rename_file (File file, string new_name) throws Error {
            return false;
        }
    }
}
