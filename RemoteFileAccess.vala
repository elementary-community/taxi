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
using Gtk;

namespace Taxi {

    class RemoteFileAccess : IFileAccess, Object {

        private IConnInfo connect_info;
        private File file_handle;
        private IFileOperations file_operation = new FileOperations ();

        public async bool connect_to_device (IConnInfo connect_info) {
            var mount = mount_operation_from_connect (connect_info);
            var uri = connect_info.get_uri ();
            file_handle = File.new_for_uri (uri);
            try {
                return yield file_handle.mount_enclosing_volume (
                    MountMountFlags.NONE,
                    mount,
                    null
                );
            } catch (Error e) {

                // Already mounted
                if (e.code == 17) {
                    return true;
                }

                message ("ERROR MOUNTING: " + e.message + "\n");

                return false;

            } finally {
                connected ();
            }
        }

        public async List<FileInfo> get_file_list () {
            try {
                return yield file_operation.get_file_list (file_handle);
            } catch (Error e) {

                // Unmounted
                if (e.code == 16) {
                    if (yield connect_to_device (connect_info)) {
                        return yield get_file_list ();
                    }
                }

                // Host closed conn
                if (e.code == 0) {
                    // Try some more times
                }

                message (e.message);

                return new List<FileInfo> ();
            }
        }

        public string get_uri () {
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
            file_handle = file_handle.resolve_relative_path ("/" + path);
        }

        private Gtk.MountOperation mount_operation_from_connect (IConnInfo connect_info) {
            var mount = new Gtk.MountOperation (new Gtk.Window ());
            mount.set_domain (connect_info.hostname);
            stdout.printf ("MOUNT HOST: " + connect_info.hostname + "\n");
            mount.set_anonymous (connect_info.anonymous);
            mount.set_password_save (PasswordSave.FOR_SESSION);
            mount.set_choice (0);
            if (!connect_info.anonymous) {
                stdout.printf ("Got here\n");
                mount.set_username (connect_info.username);
                mount.set_password (connect_info.password);
            }
            mount.ask_password.connect ((message, user, domain, flags) => {
                stdout.printf ("ENTER PASSWORD %s %s\n", message, domain);
                mount.set_password (connect_info.password);
            });
            return mount;
        }
    }
}
