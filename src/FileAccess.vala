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

    abstract class FileAccess : IFileAccess, Object {

        protected virtual File file_handle { get; set; }
        protected virtual IFileOperations file_operation { get; set; }

        public abstract async bool connect_to_device (
            IConnInfo connect_info,
            Gtk.Window window
        );

        public virtual async List<FileInfo> get_file_list () {
            try {
                return yield file_operation.get_file_list (file_handle);
            } catch (Error e) {
                message (e.message);
                return new List<FileInfo>();
            }
        }

        public virtual string get_uri () {
            return file_handle.get_uri ();
        }

        public virtual string get_path () {
            return file_handle.get_path ();
        }

        public virtual void goto_child (string name) {
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

        public virtual void goto_path (string path) {
            file_handle = File.new_for_path (path);
        }

        public virtual File get_current_file () {
            return file_handle;
        }
    }
}
