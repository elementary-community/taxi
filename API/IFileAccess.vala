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

namespace Shift {

    interface IFileAccess : GLib.Object {

        /**
         * Connects to a server
         *
         * @return true if successful at connecting
         */
        public abstract bool connect_to_server (IConnInfo conn_info);

        /**
         * Get a list of files in a remote directory
         *
         * @return a list of file information objects
         */
        public async abstract List<FileInfo> get_remote_file_list (string path);

        /**
         * Gets a list of files in a local directory
         *
         * @return a list of file information objects
         */
        public async abstract List<FileInfo> get_local_file_list (string path);

        /**
         * Gets the path that the program is currently in remotely
         *
         * @return the current remote path
         */
        public abstract string get_remote_path ();

        /**
         * Gets the path that the program is currently in locally
         *
         * @return the current local path
         */
        public abstract string get_local_path ();
    }
}
