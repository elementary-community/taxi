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

using Granite;

namespace Taxi {

    class LocalFileAccess : IFileAccess, Object {

        private File file_handle = File.new_for_path (Environment.get_home_dir ());
        private IFileOperations file_operation = new FileOperations ();

        public async bool connect_to_device (IConnInfo connect_info, Gtk.Window window) {
            return true;
        }

        public async List<FileInfo> get_file_list () {
            try {
                return yield file_operation.get_file_list (file_handle);
            } catch (Error e) {
                message (e.message);
                return new List<FileInfo>();
            }
        }

        public string get_uri () {
            return file_handle.get_uri ();
        }

        public string get_path () {
            return file_handle.get_uri ();
        }

        public void goto_child (string name) {
            var child_file = file_handle.get_child (name);
            var child_file_type = child_file.query_file_type (FileQueryInfoFlags.NONE);
            if (child_file_type == FileType.DIRECTORY) {
                file_handle = child_file;
            } else if (child_file_type == FileType.REGULAR) {
                try {
                    AppInfo.launch_default_for_uri (child_file.get_uri (), null);
                } catch (Error e) {
                    message (e.message);
                }
            }
        }

        public void goto_path (string path) {
            file_handle = File.new_for_path (path);
        }

        public File get_current_file () {
            return file_handle;
        }
    }
}
