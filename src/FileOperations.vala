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

using Gtk;
using Granite;

namespace Taxi {

    class FileOperations : IFileOperations, Object {

        public async bool trash_file (File file) throws Error {
            return false;
        }

        public async List<FileInfo> get_file_list (File file) throws Error {
            var file_enum = yield file.enumerate_children_async (
                "standard::*",
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
            var file_type = source.query_file_type (
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                cancellable
            );
            if (file_type == FileType.DIRECTORY) {
                yield destination.make_directory_async (Priority.DEFAULT, cancellable);
                source.copy_attributes (destination, flags, cancellable);
                string source_path = source.get_path ();
                string destination_path = destination.get_path ();
                var file_list = yield get_file_list (source);
                foreach (FileInfo file_info in file_list) {
                    yield copy_recursive (
                        File.new_for_path (Path.build_filename (source_path, file_info.get_name ())),
                        File.new_for_path (Path.build_filename (destination_path, file_info.get_name ())),
                        flags,
                        cancellable
                    );
                }
            } else if (file_type == FileType.REGULAR) {
                yield source.copy_async (
                    destination,
                    flags,
                    Priority.DEFAULT,
                    cancellable
                );
            }
        }

        public async bool rename_file (File file, string new_name) throws Error {
            return false;
        }
    }
}
