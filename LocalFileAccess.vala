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

namespace Shift {

    class LocalFileAccess : IFileAccess, GLib.Object {

        private File file_handle = File.new_for_path (Environment.get_home_dir ());

        public async bool connect_to_device (IConnInfo connect_info) {
            return true;
        }

        public async List<FileInfo> get_file_list (string path) {
            try {
                var file_enum = yield file_handle.enumerate_children_async (
                    "standard::*", 0, Priority.DEFAULT);
                return yield file_enum.next_files_async (5000);
            } catch (Error e) {
                stderr.printf ("PATH: " + path + " | %s\n", e.message);
            }
            return new List<FileInfo>();
        }

        public string get_path () {
            return file_handle.get_path ();
        }

        public void goto_child (string name) {
            file_handle = file_handle.get_child (name);
        }

        public void goto_path (string path) {
            file_handle = File.new_for_path (path);
        }

        public void goto_parent () {
            file_handle = file_handle.get_parent ();
        }
    }
}
